package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for primitive borrows in native helper signatures. */
final class NativeCompilerBorrowedSignatureExampleTest {
  @Test
  void forwardsSignedHelperResultsByteForByte() throws Exception {
    String source = """
        module example.signed_forward;
        classical class SignedForward {
          public long inspect(long value) { return 13; }
          public long forward(long value) { return inspect(value); }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("SignedForward.w", source), "example.signed_forward"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);
  }

  @Test
  void forwardsBorrowedParametersAcrossADirectImportByteForByte() throws Exception {
    String dependency = """
        module example.borrowed_dependency;
        classical class BorrowedDependency {
          public boolean inspect(borrow utf8 source) { return true; }
        }
        """;
    String root = """
        module example.borrowed_root;
        import example.borrowed_dependency;
        classical class BorrowedRoot {
          public boolean forward(borrow utf8 source) { return inspect(source); }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedDependency.w", dependency, "BorrowedRoot.w", root),
            "example.borrowed_root"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(dependency), root);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(dependency.replace("public boolean inspect", "private boolean inspect")),
        root);
  }

  @Test
  void reborrowsThreeAndFourPrimitiveArgumentsByteForByte() throws Exception {
    String source = """
        module example.borrowed_wide_calls;
        classical class BorrowedWideCalls {
          private long acceptThree(borrow utf8 text, borrow mut bytes output, long value) {
            return value;
          }
          public long forwardThree(borrow utf8 text, borrow mut bytes output, long value) {
            long result = acceptThree(text, output, value);
            return result;
          }
          private long acceptFour(
            borrow utf8 text,
            borrow byteview input,
            borrow mut words values,
            long fallback
          ) {
            return fallback;
          }
          public long forwardFour(
            borrow utf8 text,
            borrow byteview input,
            borrow mut words values,
            long fallback
          ) {
            long result = acceptFour(text, input, values, fallback);
            return result;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedWideCalls.w", source), "example.borrowed_wide_calls"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var decoded = new BytecodeReader().read(actual);
    assertEquals(12, decoded.functions().get(1).localCount());
    assertEquals(15, decoded.functions().get(3).localCount());
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "acceptThree(text, output, value)",
            "acceptThree(output, text, value)"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "acceptFour(text, input, values, fallback)",
            "acceptFour(text, values, input, fallback)"));
  }

  @Test
  void reborrowsFiveThroughSevenPrimitiveArgumentsByteForByte() throws Exception {
    String source = """
        module example.borrowed_widest_calls;
        classical class BorrowedWidestCalls {
          private long acceptFive(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            long fallback
          ) { return fallback; }
          public long forwardFive(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            long fallback
          ) {
            long result = acceptFive(text, input, output, values, fallback);
            return result;
          }
          private long acceptSix(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            long fallback
          ) { return fallback; }
          public long forwardSix(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            long fallback
          ) {
            long result = acceptSix(text, input, output, values, table, fallback);
            return result;
          }
          private long acceptSeven(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            borrow mut region arena,
            long fallback
          ) { return fallback; }
          public long forwardSeven(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            borrow mut region arena,
            long fallback
          ) {
            long result = acceptSeven(text, input, output, values, table, arena, fallback);
            return result;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedWidestCalls.w", source), "example.borrowed_widest_calls"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var decoded = new BytecodeReader().read(actual);
    assertEquals(18, decoded.functions().get(1).localCount());
    assertEquals(21, decoded.functions().get(3).localCount());
    assertEquals(24, decoded.functions().get(5).localCount());
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "acceptSeven(text, input, output, values, table, arena, fallback)",
            "acceptSeven(text, input, output, values, table, arena, fallback, fallback)"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "acceptSix(text, input, output, values, table, fallback)",
            "acceptSix(text, input, output, table, values, fallback)"));
  }

  @Test
  void reborrowsFourThroughSevenVoidArgumentsByteForByte() throws Exception {
    String source = """
        module example.borrowed_void_calls;
        classical class BorrowedVoidCalls {
          private void acceptFour(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            long fallback
          ) {}
          public long forwardFour(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            long fallback
          ) {
            acceptFour(text, input, output, fallback);
            return fallback;
          }
          private void acceptFive(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            long fallback
          ) {}
          public long forwardFive(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            long fallback
          ) {
            acceptFive(text, input, output, values, fallback);
            return fallback;
          }
          private void acceptSix(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            long fallback
          ) {}
          public long forwardSix(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            long fallback
          ) {
            acceptSix(text, input, output, values, table, fallback);
            return fallback;
          }
          private void acceptSeven(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            borrow mut region arena,
            long fallback
          ) {}
          public long forwardSeven(
            borrow utf8 text,
            borrow byteview input,
            borrow mut bytes output,
            borrow mut words values,
            borrow mut longmap table,
            borrow mut region arena,
            long fallback
          ) {
            acceptSeven(text, input, output, values, table, arena, fallback);
            return fallback;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedVoidCalls.w", source), "example.borrowed_void_calls"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var decoded = new BytecodeReader().read(actual);
    assertEquals(13, decoded.functions().get(1).localCount());
    assertEquals(16, decoded.functions().get(3).localCount());
    assertEquals(19, decoded.functions().get(5).localCount());
    assertEquals(22, decoded.functions().get(7).localCount());
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "acceptSeven(text, input, output, values, table, arena, fallback)",
            "acceptSeven(text, input, output, values, table, arena, fallback, fallback)"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "acceptSix(text, input, output, values, table, fallback)",
            "acceptSix(text, input, output, table, values, fallback)"));
  }

  @Test
  void compilesBorrowedUtf8AndMutableBytesParametersByteForByte() throws Exception {
    String source = """
        module example.borrowed_signatures;
        classical class BorrowedSignatures {
          public long ignoreBytes(borrow mut bytes output) { return 7; }
          public long ignoreMap(borrow mut longmap values) { return 8; }
          public long ignoreRegion(borrow mut region arena) { return 9; }
          public long ignoreText(borrow utf8 source) { return 10; }
          public long ignoreView(borrow byteview input) { return 11; }
          public long ignoreWords(borrow mut words values) { return 12; }
          public boolean mixed(long value, borrow utf8 text, borrow mut bytes output) {
            return true;
          }
          public boolean inspect(borrow utf8 source) { return true; }
          public boolean forwardText(borrow utf8 source) {
            boolean result = inspect(source);
            return result;
          }
          public boolean acceptBytes(borrow mut bytes value) { return true; }
          public boolean forwardBytes(borrow mut bytes value) {
            boolean result = acceptBytes(value);
            return result;
          }
          public boolean acceptMap(borrow mut longmap value) { return true; }
          public boolean forwardMap(borrow mut longmap value) { return acceptMap(value); }
          public boolean acceptRegion(borrow mut region value) { return true; }
          public boolean forwardRegion(borrow mut region value) { return acceptRegion(value); }
          public long acceptView(borrow byteview value) { return 11; }
          public long forwardView(borrow byteview value) {
            long result = acceptView(value);
            return result;
          }
          public boolean acceptWords(borrow mut words value) { return true; }
          public boolean forwardWords(borrow mut words value) { return acceptWords(value); }
          public boolean acceptMixed(long value, borrow utf8 text) { return true; }
          public boolean forwardMixed(long value, borrow utf8 text) {
            boolean result = acceptMixed(value, text);
            return result;
          }
          public boolean acceptPair(borrow utf8 text, borrow mut bytes output) {
            return true;
          }
          public boolean forwardPair(borrow utf8 text, borrow mut bytes output) {
            boolean result = acceptPair(text, output);
            return result;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedSignatures.w", source),
            "example.borrowed_signatures"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    var decoded = new BytecodeReader().read(actual);
    assertEquals(ValueType.BYTES_BORROW, decoded.functions().get(0).localType(0));
    assertEquals(ValueType.LONG_MAP_BORROW, decoded.functions().get(1).localType(0));
    assertEquals(ValueType.REGION_BORROW, decoded.functions().get(2).localType(0));
    assertEquals(ValueType.UTF8_BORROW, decoded.functions().get(3).localType(0));
    assertEquals(ValueType.BYTE_VIEW, decoded.functions().get(4).localType(0));
    assertEquals(ValueType.WORDS_BORROW, decoded.functions().get(5).localType(0));
    for (int function = 0; function < 6; function += 1) {
      assertEquals(1, decoded.functions().get(function).parameterCount());
    }
    assertEquals(3, decoded.functions().get(6).parameterCount());
    assertEquals(ValueType.SIGNED, decoded.functions().get(6).localType(0));
    assertEquals(ValueType.UTF8_BORROW, decoded.functions().get(6).localType(1));
    assertEquals(ValueType.BYTES_BORROW, decoded.functions().get(6).localType(2));
    assertEquals(ValueType.UTF8_BORROW, decoded.functions().get(7).localType(0));
    assertEquals(ValueType.UTF8_BORROW, decoded.functions().get(8).localType(0));

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "boolean result = acceptBytes(value);",
            "boolean result = inspect(value);"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "long result = acceptView(value);",
            "long result = ignoreText(value);"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "boolean result = acceptPair(text, output);",
            "boolean result = acceptMixed(text, output);"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow utf8 source", "borrow mut utf8 source"));
  }
}
