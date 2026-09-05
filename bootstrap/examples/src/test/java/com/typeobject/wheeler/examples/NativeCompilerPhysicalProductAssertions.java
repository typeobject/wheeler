package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Compares retained callable bodies after binding the physical transport's relocations. */
final class NativeCompilerPhysicalProductAssertions {
  private record Product(String module, int start, int length, int functions) {}

  private record Relocation(int instruction, String module, int function) {}

  private NativeCompilerPhysicalProductAssertions() {}

  static void assertCallables(
      BootstrapModuleManifest manifest, Map<String, Program> expected, byte[] transport) {
    assertFalse(expected.isEmpty(), "callable comparison set");
    assertTrue(8 <= transport.length, "transport footer");
    ByteBuffer footer = ByteBuffer.wrap(transport, transport.length - 8, 8);
    assertEquals(0x57504601, footer.getInt(), "transport magic and version");
    int productCount = Short.toUnsignedInt(footer.getShort());
    int relocationCount = Short.toUnsignedInt(footer.getShort());
    int metadataStart = transport.length - 8 - productCount * 6 - relocationCount * 6;
    assertTrue(0 <= metadataStart, "transport metadata extent");
    ByteBuffer metadata = ByteBuffer.wrap(transport, metadataStart, productCount * 6);
    List<Product> products = products(manifest, metadata, productCount, metadataStart);
    ByteBuffer relocationBytes = ByteBuffer.wrap(
        transport, metadataStart + productCount * 6, relocationCount * 6);
    var relocations = relocations(manifest, relocationBytes, productCount, relocationCount);

    Set<String> compared = new HashSet<>();
    for (int index = 0; index < products.size(); index++) {
      Product product = products.get(index);
      Program reference = expected.get(product.module());
      if (reference != null) {
        assertProduct(product, reference, relocations.getOrDefault(index, List.of()), transport);
        compared.add(product.module());
      }
    }
    assertEquals(expected.keySet(), compared, "every selected callable product must be present");
  }

  private static List<Product> products(
      BootstrapModuleManifest manifest, ByteBuffer metadata, int count, int end) {
    List<Product> products = new ArrayList<>();
    Set<Integer> owners = new HashSet<>();
    int start = 0;
    for (int index = 0; index < count; index++) {
      int owner = Short.toUnsignedInt(metadata.getShort());
      assertTrue(owner < manifest.modules().size(), "product owner");
      assertTrue(owners.add(owner), "duplicate product owner");
      int length = Byte.toUnsignedInt(metadata.get()) * 65536
          + Short.toUnsignedInt(metadata.getShort());
      int functions = Byte.toUnsignedInt(metadata.get());
      assertTrue(0 < length && length <= end - start, "product extent");
      products.add(new Product(manifest.modules().get(owner).name(), start, length, functions));
      start += length;
    }
    assertEquals(end, start, "complete product byte extent");
    return List.copyOf(products);
  }

  private static Map<Integer, List<Relocation>> relocations(
      BootstrapModuleManifest manifest, ByteBuffer bytes, int products, int count) {
    Map<Integer, List<Relocation>> rows = new HashMap<>();
    int previousProduct = -1;
    int previousInstruction = -1;
    for (int index = 0; index < count; index++) {
      int product = Byte.toUnsignedInt(bytes.get());
      int instruction = Short.toUnsignedInt(bytes.getShort());
      int owner = Short.toUnsignedInt(bytes.getShort());
      int function = Byte.toUnsignedInt(bytes.get());
      assertTrue(product < products, "relocation product");
      assertTrue(owner < manifest.modules().size(), "relocation owner");
      assertTrue(previousProduct < product
          || previousProduct == product && previousInstruction < instruction,
          "strict relocation order");
      rows.computeIfAbsent(product, unused -> new ArrayList<>()).add(
          new Relocation(instruction, manifest.modules().get(owner).name(), function));
      previousProduct = product;
      previousInstruction = instruction;
    }
    return rows;
  }

  private static void assertProduct(
      Product product, Program expected, List<Relocation> relocations, byte[] transport) {
    List<FunctionBody> functions = moduleFunctions(expected, product.module());
    assertEquals(functions.size(), product.functions(), product.module() + " retained functions");
    Map<Integer, Integer> targets = new HashMap<>();
    for (Relocation relocation : relocations) {
      List<FunctionBody> candidates = moduleFunctions(expected, relocation.module());
      assertTrue(relocation.function() < candidates.size(), relocation.module() + " target");
      targets.put(relocation.instruction(), candidates.get(relocation.function()).id());
    }

    Program actual = new BytecodeReader().read(Arrays.copyOfRange(
        transport, product.start(), product.start() + product.length()));
    assertTrue(product.functions() <= actual.functions().size(), "retained function window");
    int instruction = 0;
    for (int index = 0; index < product.functions(); index++) {
      FunctionBody function = actual.functions().get(index);
      assertEquals(index, function.id(), "source-local function ID");
      List<Instruction> forward = relocate(function.forward(), instruction, functions, targets);
      instruction += forward.size();
      List<Instruction> inverse = relocate(function.inverse(), instruction, functions, targets);
      instruction += inverse.size();
      FunctionBody relocated = new FunctionBody(
          functions.get(index).id(), function.name(), function.coherent(),
          function.parameterCount(), function.localTypes(), function.resultType(),
          function.implicitResultSlot(), forward, inverse);
      assertEquals(functions.get(index), relocated, function.name());
    }
    assertTrue(targets.isEmpty(), "every relocation must name a retained instruction");
  }

  private static List<FunctionBody> moduleFunctions(Program program, String module) {
    return program.functions().stream()
        .filter(function -> function.name().startsWith(module + "::")).toList();
  }

  private static List<Instruction> relocate(
      List<Instruction> source, int first, List<FunctionBody> functions, Map<Integer, Integer> targets) {
    List<Instruction> result = new ArrayList<>();
    for (int index = 0; index < source.size(); index++) {
      Instruction instruction = source.get(index);
      Integer target = targets.remove(first + index);
      int operand = instruction.opcode().form().roles().indexOf(OperandRole.FUNCTION);
      if (target != null) {
        assertTrue(0 <= operand, "relocation must name a call target");
        assertTrue(functions.size() <= instruction.operands().get(operand), "imported target");
      } else if (0 <= operand) {
        int local = Math.toIntExact(instruction.operands().get(operand));
        assertTrue(0 <= local && local < functions.size(), "missing imported relocation");
        target = functions.get(local).id();
      }
      if (target != null) {
        List<Long> operands = new ArrayList<>(instruction.operands());
        operands.set(operand, target.longValue());
        instruction = new Instruction(instruction.opcode(), operands);
      }
      result.add(instruction);
    }
    return List.copyOf(result);
  }
}
