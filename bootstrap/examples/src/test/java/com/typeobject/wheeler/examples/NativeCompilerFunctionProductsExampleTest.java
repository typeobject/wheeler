package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for canonical function and instruction products. */
final class NativeCompilerFunctionProductsExampleTest {
  @Test
  void decodesCanonicalFunctionDescriptorsAndInstructions() throws Exception {
    Program product = product();
    byte[] artifact = new BytecodeWriter().write(product);
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact);

    machine.run();

    long instructions = product.functions().stream()
        .mapToLong(function -> function.forward().size() + function.inverse().size())
        .sum();
    long maxLocals = product.functions().stream()
        .mapToLong(function -> function.localTypes().size())
        .max()
        .orElseThrow();
    assertEquals(product.functions().size(), machine.global("functionCount"));
    assertEquals(instructions, machine.global("instructionCount"));
    assertEquals(maxLocals, machine.global("maxLocalCount"));
    assertEquals(product.functions().getFirst().forward().getFirst().opcode().code(),
        machine.global("firstOpcode"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsUnknownExecutableOpcodesBeforePublication() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    int codeStart = sectionStart(artifact, 6);
    artifact[codeStart] = (byte) 0xff;
    artifact[codeStart + 1] = (byte) 0xff;
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  @Test
  void rejectsNoncontiguousFunctionCodeBeforePublication() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    int functionsStart = sectionStart(artifact, 5);
    putInt(artifact, functionsStart + 16, 1);
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(), artifact);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program decoder() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.put("FunctionProductsExample.w", """
        module example.function_products;

        import wheeler.compiler.closure.compiled_function_products;

        classical class FunctionProductsExample {
          state long functionCount = 0;
          state long instructionCount = 0;
          state long maxLocalCount = 0;
          state long firstOpcode = 0;
          state long published = 0;

          entry void main(borrow byteview source) {
            region rows = new region(/* bytes= */ 201728, /* allocations= */ 2);
            words functions = allocate(rows, /* length= */ 640);
            words instructions = allocate(rows, /* length= */ 24576);
            CompiledFunctionPlan plan = indexCompiledFunctionProducts(
              source,
              bufferLength(source),
              functions,
              instructions
            );
            functionCount = plan.functionCount;
            instructionCount = plan.instructionCount;
            maxLocalCount = plan.maxLocalCount;
            firstOpcode = instructions[12288];
            published = 1;
            drop(instructions);
            drop(functions);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.function_products");
  }

  private static Program product() {
    String source = """
        module fixture.function_products;

        classical class FunctionProducts {
          long identity(long value) {
            return value;
          }

          entry void main() {
            long value = identity(7);
            assert(value == 7);
          }
        }
        """;
    return new WheelerCompiler().compileModuleFiles(
        Map.of("FunctionProducts.w", source),
        "fixture.function_products");
  }

  private static int sectionStart(byte[] artifact, int wantedType) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int sections = bytes.getInt(24);
    for (int index = 0; index < sections; index++) {
      int directory = 40 + index * 32;
      if (bytes.getInt(directory) == wantedType) {
        return Math.toIntExact(bytes.getLong(directory + 8));
      }
    }
    throw new AssertionError("missing section " + wantedType);
  }

  private static void putInt(byte[] bytes, int offset, int value) {
    ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).putInt(offset, value);
  }
}
