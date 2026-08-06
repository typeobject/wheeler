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
          public boolean forwardText(borrow utf8 source) { return inspect(source); }
          public boolean acceptBytes(borrow mut bytes value) { return true; }
          public boolean forwardBytes(borrow mut bytes value) { return acceptBytes(value); }
          public boolean acceptMap(borrow mut longmap value) { return true; }
          public boolean forwardMap(borrow mut longmap value) { return acceptMap(value); }
          public boolean acceptRegion(borrow mut region value) { return true; }
          public boolean forwardRegion(borrow mut region value) { return acceptRegion(value); }
          public boolean acceptView(borrow byteview value) { return true; }
          public boolean forwardView(borrow byteview value) { return acceptView(value); }
          public boolean acceptWords(borrow mut words value) { return true; }
          public boolean forwardWords(borrow mut words value) { return acceptWords(value); }
          public boolean acceptMixed(long value, borrow utf8 text) { return true; }
          public boolean forwardMixed(long value, borrow utf8 text) {
            return acceptMixed(value, text);
          }
          public boolean acceptPair(borrow utf8 text, borrow mut bytes output) {
            return true;
          }
          public boolean forwardPair(borrow utf8 text, borrow mut bytes output) {
            return acceptPair(text, output);
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
        source.replace("return acceptBytes(value);", "return inspect(value);"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow utf8 source", "borrow mut utf8 source"));
  }
}
