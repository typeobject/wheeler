package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
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
          public long directScalar(borrow utf8 value, long index) {
            return utf8Scalar(value, index);
          }
          public long directWidth(borrow utf8 value, long index) {
            return utf8Width(value, index);
          }
          private long select(borrow utf8 value, long index, long fallback, long spare) {
            return utf8Scalar(value, index);
          }
          public long relay(borrow utf8 value, long index, long fallback, long spare) {
            return select(value, index, fallback, spare);
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
    var relay = new BytecodeReader().read(actual).functions().get(6);
    assertEquals(13, relay.localCount());
    assertEquals(10, relay.forward().size());

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("borrow utf8 value", "borrow byteview value"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace("long index", "borrow utf8 index"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "return select(value, index, fallback, spare);",
            "return select(value, index, fallback, spare, spare);"));
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
          public long direct(borrow mut words value, long index) {
            return value[index];
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
          public long directLookup(borrow mut longmap values, long key) {
            return mapGet(values, key);
          }
          public boolean directContains(borrow mut longmap values, long key) {
            return mapHas(values, key);
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
  void compilesOneFixedArrayHelperByteForByte() throws Exception {
    String source = """
        module example.one_fixed_array_helper;
        classical class OneFixedArrayHelper {
          public long lookup(long[7] values, long index, long fallback) {
            return values[index];
          }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("OneFixedArrayHelper.w", source), "example.one_fixed_array_helper"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    Program decoded = new BytecodeReader().read(actual);
    assertEquals("example.one_fixed_array_helper::lookup", decoded.functions().getFirst().name());
    assertEquals("$library", decoded.functions().getLast().name());
    assertEquals(2, decoded.functions().size());

    for (String visibility : List.of("private ", "")) {
      String variant = source.replace("public long lookup", visibility + "long lookup");
      byte[] variantExpected = new BytecodeWriter().write(
          new WheelerCompiler().compileLibraryModuleFiles(
              Map.of("OneFixedArrayHelper.w", variant), "example.one_fixed_array_helper"));
      assertArrayEquals(
          variantExpected,
          NativeModuleCompilerHarness.compile(
              NativeModuleCompilerHarness.program(), List.of(), variant));
    }
  }

  @Test
  void compilesFixedSignedArrayReadsByteForByte() throws Exception {
    String source = """
        module example.fixed_array_read;
        classical class FixedArrayRead {
          public long lookup(long[4] values, long index) {
            long element = values[index];
            return element;
          }
          public long second(long[4] values) {
            long index = 1;
            long element = values[index];
            return element;
          }
          public long relay(long[4] values, long index) {
            return lookup(values, index);
          }
          public long other(long[3] values, long index) {
            long element = values[index];
            return element;
          }
          public long direct(long[3] values, long index) {
            return values[index];
          }
          private long choose(long[4] values, long index, long fallback) {
            return values[index];
          }
          public long relayThree(long[4] values, long index, long fallback) {
            return choose(values, index, fallback);
          }
          public long dummy() { return 0; }
        }
        """;
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("FixedArrayRead.w", source), "example.fixed_array_read"));
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(), List.of(), source.replace("long[4]", "long[0]"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(), List.of(), source.replace("long[4]", "long[65]"));
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(), List.of(),
        source.replace("choose(values, index, fallback)",
            "choose(values, index, fallback, index)"));

    StringBuilder tooManyTypes = new StringBuilder("""
        module example.too_many_array_types;
        classical class TooManyArrayTypes {
        """);
    for (int length = 1; length <= 17; length += 1) {
      tooManyTypes.append("  public long read")
          .append(length)
          .append("(long[")
          .append(length)
          .append("] values, long index) { long value = values[index]; return value; }\n");
    }
    tooManyTypes.append("}\n");
    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(), List.of(), tooManyTypes.toString());
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
