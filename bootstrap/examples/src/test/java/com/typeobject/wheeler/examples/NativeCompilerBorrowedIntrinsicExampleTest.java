package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for intrinsic access through primitive loans. */
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
  void compilesSignedMapReadsByteForByte() throws Exception {
    String source = """
        module example.borrowed_map_read;
        classical class BorrowedMapRead {
          public long lookup(borrow mut longmap values, long key) {
            long element = mapGet(values, key);
            return element;
          }
          public boolean contains(borrow mut longmap values, long key) {
            boolean present = mapHas(values, key);
            return present;
          }
          public long dummy() { return 0; }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedMapRead.w", source), "example.borrowed_map_read"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow mut longmap values", "borrow mut region values"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("long key", "borrow utf8 key"));
  }

  @Test
  void compilesPrimitiveLoanVoidWritersByteForByte() throws Exception {
    String source = """
        module example.borrowed_loan_void_write;
        classical class BorrowedLoanVoidWrite {
          private void octet(borrow mut bytes values, long index, long element) {
            setByte(values, index, element);
          }
          private long dummy() { return 0; }
          private void word(borrow mut words values, long index, long element) {
            set(values, index, element);
          }
          private void mapping(borrow mut longmap values, long key, long element) {
            put(values, key, element);
          }
          private void idle() {}
          private void inspect(borrow mut bytes values) {}
          private void locate(borrow mut words values, long index) {}
          private void relay(borrow mut bytes output, borrow mut words values, long index) {
            idle();
            inspect(output);
            locate(values, index);
            octet(output, index, index);
          }
          private long dispatch(borrow mut bytes output, long index) {
            inspect(output);
            return index;
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedLoanVoidWrite.w", source), "example.borrowed_loan_void_write"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "set(values, index, element);\n  }",
            "set(values, index, element);\n    return element;\n  }"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("private long dummy() { return 0; }", "private long dummy() {}"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("inspect(output);", "inspect(values);"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("inspect(output);", "inspect();"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("idle();", "dummy();"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("octet(output, index, index);", "octet(output, index, output);"));
  }

  @Test
  void compilesPrimitiveLoanWritesByteForByte() throws Exception {
    String source = """
        module example.borrowed_loan_write;
        classical class BorrowedLoanWrite {
          public long word(borrow mut words values, long index, long element) {
            set(values, index, element);
            return element;
          }
          public long octet(borrow mut bytes values, long index, long element) {
            setByte(values, index, element);
            return element;
          }
          public long mapping(borrow mut longmap values, long key, long element) {
            put(values, key, element);
            return element;
          }
          public long dummy() { return 0; }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("BorrowedLoanWrite.w", source), "example.borrowed_loan_write"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow mut words values", "borrow mut region values"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow mut bytes values", "borrow byteview values"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow mut longmap values", "borrow mut region values"));
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
