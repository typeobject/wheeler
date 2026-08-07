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

          public long selectThree(long left, long middle, long right) {
            return left;
          }

          public long selectFour(long first, long second, long third, long fourth) {
            return fourth;
          }

          public boolean threeReady(long left, long middle, long right) {
            return false;
          }

          public boolean fourReady(long first, long second, long third, long fourth) {
            return false;
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

          public long selected(long value) {
            long result = selectThree(value, value, value);
            return result;
          }

          public long selectedFour(long value) {
            long result = selectFour(value, value, value, value);
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
    assertEquals(1, firstCallTarget(decoded, 8));
    assertEquals(2, firstCallTarget(decoded, 9));
    assertEquals(3, firstCallTarget(decoded, 10));
    assertEquals(4, firstCallTarget(decoded, 11));
    assertEquals(5, firstCallTarget(decoded, 12));
    assertEquals(10, decoded.functions().get(11).localCount());
    assertEquals(10, decoded.functions().get(11).forward().size());
    assertEquals(12, decoded.functions().get(12).localCount());
    assertEquals(12, decoded.functions().get(12).forward().size());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("identity(value)", "skipped(value)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("selectThree(value, value, value)", "threeReady(value, value, value)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("selectThree(value, value, value)", "selectThree(value, value)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("selectThree(value, value, value)", "selectThree(value, value, 0)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace(
            "selectFour(value, value, value, value)",
            "fourReady(value, value, value, value)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace(
            "selectFour(value, value, value, value)",
            "selectFour(value, value, value)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace(
            "selectFour(value, value, value, value)",
            "selectFour(value, value, value, 0)"));
  }

  @Test
  void assignsZeroThroughSevenTypedCallArgumentsByteForByte() throws Exception {
    String source = """
        module example.assigned_calls;
        classical class AssignedCalls {
          public long zero() {
            return 0;
          }

          public long one(long first) {
            return first;
          }

          public long two(long first, long second) {
            return first;
          }

          public long three(long first, long second, long third) {
            return first;
          }

          public long four(long first, long second, long third, long fourth) {
            return first;
          }

          public long five(long first, long second, long third, long fourth, long fifth) {
            return first;
          }

          public long six(
            long first,
            long second,
            long third,
            long fourth,
            long fifth,
            long sixth
          ) {
            return first;
          }

          public long seven(
            borrow utf8 text,
            borrow byteview view,
            borrow mut bytes octets,
            borrow mut words values,
            borrow mut region arena,
            borrow mut longmap table,
            long seed
          ) {
            return seed;
          }

          public long assignAll(
            borrow utf8 text,
            borrow byteview view,
            borrow mut bytes octets,
            borrow mut words values,
            borrow mut region arena,
            borrow mut longmap table,
            long seed
          ) {
            long result = seed;
            result = zero();
            result = one(seed);
            result = two(seed, seed);
            result = three(seed, seed, seed);
            result = four(seed, seed, seed, seed);
            result = five(seed, seed, seed, seed, seed);
            result = six(seed, seed, seed, seed, seed, seed);
            result = seven(text, view, octets, values, arena, table, seed);
            return result;
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(), source);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("AssignedCalls.w", source), "example.assigned_calls");
    assertArrayEquals(new BytecodeWriter().write(expected), actual);

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(),
        source.replace(
            "seven(text, view, octets, values, arena, table, seed)",
            "seven(text, view, values, octets, arena, table, seed)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(),
        source.replace(
            "seven(text, view, octets, values, arena, table, seed)",
            "seven(text, view, octets, values, arena, table, seed, seed)"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(),
        source.replace("long result = seed;", "boolean result = false;"));
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
