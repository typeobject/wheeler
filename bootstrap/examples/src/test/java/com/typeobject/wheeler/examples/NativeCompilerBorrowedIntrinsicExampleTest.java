package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for intrinsic reads through primitive loans. */
final class NativeCompilerBorrowedIntrinsicExampleTest {
  @Test
  void compilesBufferLengthByteForByte() throws Exception {
    String source = """
        module example.borrowed_intrinsic;
        classical class BorrowedIntrinsic {
          public long sizeBytes(borrow mut bytes value) { return bufferLength(value); }
          public long sizeText(borrow utf8 value) { return bufferLength(value); }
          public long sizeView(borrow byteview value) { return bufferLength(value); }
          public long sizeWords(borrow mut words value) { return bufferLength(value); }
          public long dummy() { return 0; }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedIntrinsic.w", source), "example.borrowed_intrinsic"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow mut bytes value", "long value"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow mut bytes value", "borrow mut region value"));
  }

  @Test
  void compilesBorrowedLengthLocalByteForByte() throws Exception {
    String source = """
        module example.borrowed_intrinsic_local;
        classical class BorrowedIntrinsicLocal {
          public long size(borrow byteview value) {
            long length = bufferLength(value);
            return length;
          }
          public long dummy() { return 0; }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedIntrinsicLocal.w", source), "example.borrowed_intrinsic_local"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow byteview value", "long value"));
  }
}
