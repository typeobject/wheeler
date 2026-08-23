package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for the complete 255-case report and adapter boundary. */
final class NativeTestReportBoundExampleTest {
  private static final int MAX_CASES = 255;

  @Test
  void reducesTwoHundredFiftyFiveRowsAndRejectsTheNext() throws Exception {
    Program reducer = reportRowsProgram();
    byte[] rows = rows(MAX_CASES);
    byte[] input = rowInput(MAX_CASES, rows);
    byte[] reduced = execute(reducer, input, 36 + rows.length);

    assertEquals(36 + rows.length, reduced.length);
    assertEquals(identityText(1), caseIdentity(reduced, 36));
    assertEquals(identityText(MAX_CASES), caseIdentity(reduced, lastRowStart(reduced, 36)));

    byte[] rejectedRows = rows(MAX_CASES + 1);
    byte[] rejectedInput = rowInput(MAX_CASES + 1, rejectedRows);
    VirtualMachine rejected = VirtualMachine.withBinaryInput(
        reducer, rejectedInput, 36 + rejectedRows.length);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(rejected));
    assertArrayEquals(new byte[36 + rejectedRows.length], rejected.hostOutput());
  }

  @Test
  void rendersTwoHundredFiftyFiveCanonicalRows() throws Exception {
    byte[] rows = rows(MAX_CASES);
    byte[] reduced = execute(
        reportRowsProgram(), rowInput(MAX_CASES, rows), 36 + rows.length);
    byte[] canonicalRows = Arrays.copyOfRange(reduced, 36, reduced.length);
    byte[] adapterInput = adapterInput(reduced, canonicalRows);
    int capacity = 512 + canonicalRows.length * 2 + MAX_CASES * 256;

    String json = text(execute(
        renderer("TestReportJson", "NativeTestReportJson", "native_test_report_json"),
        adapterInput,
        capacity));
    String junit = text(execute(
        renderer("TestReportJunit", "NativeTestReportJunit", "native_test_report_junit"),
        adapterInput,
        capacity));
    String terminal = text(execute(
        renderer("TestReportTerminal", "NativeTestReportTerminal", "native_test_report_terminal"),
        adapterInput,
        capacity));

    assertTrue(json.contains("\"selected\":255"));
    assertTrue(junit.contains("tests=\"255\""));
    assertTrue(terminal.contains("(255 cases, 255 passed"));
  }

  private static Program reportRowsProgram() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("TestLimits.w", RuntimeSources.read("runtime/testing/TestLimits.w"));
    sources.put(
        "TestReportIdentity.w",
        RuntimeSources.read("runtime/testing/reports/TestReportIdentity.w"));
    sources.put(
        "TestReportRows.w",
        RuntimeSources.read("runtime/testing/reports/TestReportRows.w"));
    sources.put(
        "NativeTestReportRows.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/reports/NativeTestReportRows.w")));
    return new WheelerCompiler().compileModuleFiles(
        sources, "wheeler.conformance.testing.native_test_report_rows");
  }

  private static Program renderer(String runtime, String nativeSource, String module)
      throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("TestLimits.w", RuntimeSources.read("runtime/testing/TestLimits.w"));
    sources.put(
        "TestReportAdapter.w",
        RuntimeSources.read("runtime/testing/reports/TestReportAdapter.w"));
    sources.put(
        runtime + ".w",
        RuntimeSources.read("runtime/testing/reports/" + runtime + ".w"));
    sources.put(
        nativeSource + ".w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/reports/"
                + nativeSource + ".w")));
    return new WheelerCompiler().compileModuleFiles(
        sources, "wheeler.conformance.testing.reports." + module);
  }

  private static byte[] rows(int count) {
    ByteArrayOutputStream rows = new ByteArrayOutputStream();
    for (int index = count; 0 < index; index--) {
      writeField(rows, "pkg");
      writeField(rows, "1");
      writeField(rows, "target::case" + index);
      writeField(rows, identityText(index));
      writeField(rows, identityText(1000));
      writeField(rows, identityText(1001));
      writeField(rows, "");
      writeField(rows, "");
      writeField(rows, identityText(1002));
      writeField(rows, identityText(1003));
      rows.write(0);
      rows.writeBytes(ByteBuffer.allocate(16)
          .order(ByteOrder.LITTLE_ENDIAN)
          .putLong(1)
          .putLong(0)
          .array());
    }
    return rows.toByteArray();
  }

  private static byte[] rowInput(int count, byte[] rows) {
    return ByteBuffer.allocate(6 + rows.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) count)
        .putInt(rows.length)
        .put(rows)
        .array();
  }

  private static byte[] adapterInput(byte[] reduced, byte[] rows) {
    byte[] subject = "pkg".getBytes(StandardCharsets.UTF_8);
    return ByteBuffer.allocate(32 + 2 + subject.length + 6 + 4 + rows.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .put(reduced, 0, 32)
        .putShort((short) subject.length)
        .put(subject)
        .putShort((short) MAX_CASES)
        .putShort((short) MAX_CASES)
        .putShort((short) 0)
        .putInt(rows.length)
        .put(rows)
        .array();
  }

  private static void writeField(ByteArrayOutputStream output, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length % 256);
    output.write(bytes.length / 256);
    output.writeBytes(bytes);
  }

  private static int lastRowStart(byte[] rows, int start) {
    int cursor = start;
    int last = start;
    for (int index = 0; index < MAX_CASES; index++) {
      last = cursor;
      cursor = rowEnd(rows, cursor);
    }
    return last;
  }

  private static String caseIdentity(byte[] rows, int start) {
    int cursor = start;
    for (int field = 0; field < 3; field++) {
      int length = unsigned16(rows, cursor);
      cursor += 2 + length;
    }
    int length = unsigned16(rows, cursor);
    cursor += 2;
    return new String(rows, cursor, length, StandardCharsets.US_ASCII);
  }

  private static int rowEnd(byte[] rows, int start) {
    int cursor = start;
    for (int field = 0; field < 10; field++) {
      int length = unsigned16(rows, cursor);
      cursor += 2 + length;
    }
    return cursor + 17;
  }

  private static int unsigned16(byte[] bytes, int offset) {
    return Byte.toUnsignedInt(bytes[offset]) + Byte.toUnsignedInt(bytes[offset + 1]) * 256;
  }

  private static String identityText(int value) {
    return "%064x".formatted(value);
  }

  private static String text(byte[] bytes) {
    return new String(bytes, StandardCharsets.UTF_8);
  }

  private static byte[] execute(Program program, byte[] input, int outputCapacity) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, input, outputCapacity);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }
}
