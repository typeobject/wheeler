package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import com.typeobject.wheeler.core.bytecode.Program;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Compares retained callable bodies after binding the physical transport's relocations. */
final class NativeCompilerPhysicalProductAssertions {
  private NativeCompilerPhysicalProductAssertions() {}

  static void assertSingleCallable(String module, Program expected, byte[] transport)
      throws Exception {
    ByteBuffer footer = ByteBuffer.wrap(transport, transport.length - 8, 8);
    assertEquals(0x57504601, footer.getInt());
    assertEquals(1, Short.toUnsignedInt(footer.getShort()));
    int relocationCount = Short.toUnsignedInt(footer.getShort());
    int metadataStart = transport.length - 8 - 6 - relocationCount * 6;
    ByteBuffer metadata = ByteBuffer.wrap(transport, metadataStart, 6);
    int owner = Short.toUnsignedInt(metadata.getShort());
    int artifactLength = Byte.toUnsignedInt(metadata.get()) * 65536
        + Short.toUnsignedInt(metadata.getShort());
    int functionCount = Byte.toUnsignedInt(metadata.get());
    assertEquals(metadataStart, artifactLength);
    var manifest = CompilerSources.bootstrapModuleManifest();
    assertEquals(module, manifest.modules().get(owner).name());
    var expectedFunctions = expected.functions().stream()
        .filter(function -> function.name().startsWith(module + "::")).toList();
    assertEquals(expectedFunctions.size(), functionCount);

    Map<Integer, Integer> targets = new HashMap<>();
    ByteBuffer relocations = ByteBuffer.wrap(transport, metadataStart + 6, relocationCount * 6);
    for (int index = 0; index < relocationCount; index++) {
      assertEquals(0, Byte.toUnsignedInt(relocations.get()));
      int instruction = Short.toUnsignedInt(relocations.getShort());
      int targetOwner = Short.toUnsignedInt(relocations.getShort());
      int targetLocal = Byte.toUnsignedInt(relocations.get());
      String targetModule = manifest.modules().get(targetOwner).name();
      var candidates = expected.functions().stream()
          .filter(function -> function.name().startsWith(targetModule + "::")).toList();
      assertTrue(targetLocal < candidates.size(), targetModule);
      assertNull(targets.put(instruction, candidates.get(targetLocal).id()));
    }

    Program actual = new BytecodeReader().read(Arrays.copyOf(transport, artifactLength));
    int instruction = 0;
    for (int index = 0; index < functionCount; index++) {
      FunctionBody function = actual.functions().get(index);
      assertEquals(index, function.id(), "source-local function ID");
      List<Instruction> forward = relocate(function.forward(), instruction, expectedFunctions, targets);
      instruction += forward.size();
      List<Instruction> inverse = relocate(function.inverse(), instruction, expectedFunctions, targets);
      instruction += inverse.size();
      FunctionBody relocated = new FunctionBody(
          expectedFunctions.get(index).id(), function.name(), function.coherent(),
          function.parameterCount(), function.localTypes(), function.resultType(),
          function.implicitResultSlot(),
          forward, inverse);
      assertEquals(expectedFunctions.get(index), relocated, function.name());
    }
    assertTrue(targets.isEmpty(), "every relocation must name a retained instruction");
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
