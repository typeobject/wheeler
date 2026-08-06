package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded scalar local helper calls. */
final class NativeCompilerLocalCallExampleTest {
  @Test
  void resolvesScalarLocalCallFunctionsByteForByte() throws Exception {
    String dependency = """
        module example.local_values;
        classical class LocalValues {
          public boolean skipped(long value) {
            return false;
          }

          public long identity(long value) {
            return value;
          }

          public long answer() {
            return 42;
          }

          public long sum(long left, long right) {
            return left + right;
          }
        }
        """;
    String root = """
        module example.local_value_root;
        import example.local_values;
        classical class LocalValueRoot {
          public long copied(long value) {
            long result = identity(value);
            return result;
          }

          public long fixed() {
            long result = answer();
            return result;
          }

          public long summed(long value) {
            long result = sum(value, value);
            return result;
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("LocalValues.w", dependency, "LocalValueRoot.w", root),
        "example.local_value_root");
    assertArrayEquals(new BytecodeWriter().write(expected), actual);
    Program decoded = new BytecodeReader().read(actual);
    assertEquals(1, firstCallTarget(decoded, 4));
    assertEquals(2, firstCallTarget(decoded, 5));
    assertEquals(3, firstCallTarget(decoded, 6));

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("identity(value)", "skipped(value)"));
  }

  private static long firstCallTarget(Program program, int function) {
    return program.functions().get(function).forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.CALL_VALUE)
        .findFirst()
        .orElseThrow()
        .operands()
        .getFirst();
  }
}
