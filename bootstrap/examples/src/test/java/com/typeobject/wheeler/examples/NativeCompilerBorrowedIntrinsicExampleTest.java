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
  void compilesBorrowedUtf8ScalarLocalByteForByte() throws Exception {
    String source = """
        module example.borrowed_utf8_scalar;
        classical class BorrowedUtf8Scalar {
          public long scalar(borrow utf8 value, long index) {
            long scalar = utf8Scalar(value, index);
            return scalar;
          }
          public long second(borrow utf8 value) {
            long index = 1;
            long scalar = utf8Scalar(value, index);
            return scalar;
          }
          public long width(borrow utf8 value, long index) {
            long width = utf8Width(value, index);
            return width;
          }
          public long dummy() { return 0; }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedUtf8Scalar.w", source), "example.borrowed_utf8_scalar"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow utf8 value", "borrow byteview value"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("long index", "borrow utf8 index"));
  }

  @Test
  void compilesBorrowedBufferElementLocalByteForByte() throws Exception {
    String source = """
        module example.borrowed_buffer_element;
        classical class BorrowedBufferElement {
          public long word(borrow mut words value, long index) {
            long element = value[index];
            return element;
          }
          public long octet(borrow byteview value) {
            long index = 1;
            long element = value[index];
            return element;
          }
          public long dummy() { return 0; }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedBufferElement.w", source), "example.borrowed_buffer_element"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow mut words value", "borrow mut region value"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("long index", "borrow utf8 index"));
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
