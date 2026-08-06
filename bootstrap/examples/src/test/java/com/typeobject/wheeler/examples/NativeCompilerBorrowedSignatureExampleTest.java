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

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow utf8 source", "borrow mut utf8 source"));
  }
}
