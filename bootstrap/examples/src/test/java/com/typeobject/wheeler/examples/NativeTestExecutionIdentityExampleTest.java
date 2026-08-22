package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

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
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import org.junit.jupiter.api.Test;

/** Differential evidence for runtime-owned profile-2 execution identities. */
final class NativeTestExecutionIdentityExampleTest {
  private static Program compiledProgram;

  @Test
  void reproducesCompleteStageZeroExecutionTranscripts() throws Exception {
    for (int kind = 0; kind < 3; kind++) {
      Execution value = new Execution(
          "pkg.main", kind, Map.of("z", -7L, "alpha", 9L),
          List.of(-1L, 7L), List.of("job-a", "µ-job"), 3,
          new byte[] {0, 1, (byte) 255});
      assertArrayEquals(expected(value), execute(frame(value)));
    }
  }

  @Test
  void rejectsDuplicateGlobalsAndMalformedTailsBeforePublication() throws Exception {
    Execution value = new Execution(
        "pkg.main", 0, Map.of("alpha", 1L), List.of(), List.of(), 0, new byte[0]);
    byte[] duplicate = frame(value, List.of("alpha", "alpha"), List.of(1L, 2L));
    assertRejected(duplicate);

    byte[] negativeWorkflow = frame(new Execution(
        "pkg.main", 0, Map.of(), List.of(), List.of(), -1, new byte[0]));
    assertRejected(negativeWorkflow);
    byte[] truncated = frame(value);
    assertRejected(java.util.Arrays.copyOf(truncated, truncated.length - 1));
  }

  private static byte[] expected(Execution value) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    field(digest, "wheeler.test-execution/1");
    field(digest, value.program());
    field(digest, List.of("CLASSICAL", "QUANTUM", "HYBRID").get(value.kind()));
    Map<String, Long> globals = new TreeMap<>(value.globals());
    integer(digest, globals.size());
    globals.forEach((name, scalar) -> {
      field(digest, name);
      integer(digest, scalar);
    });
    integer(digest, value.measurements().size());
    value.measurements().forEach(item -> integer(digest, item));
    integer(digest, value.jobs().size());
    value.jobs().forEach(item -> field(digest, item));
    integer(digest, value.workflowSteps());
    bytes(digest, value.output());
    return digest.digest();
  }

  private static byte[] frame(Execution value) {
    return frame(value, List.copyOf(value.globals().keySet()),
        value.globals().keySet().stream().map(value.globals()::get).toList());
  }

  private static byte[] frame(
      Execution value, List<String> globalNames, List<Long> globalValues) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeField(output, value.program());
    output.write(value.kind());
    writeShort(output, globalNames.size());
    for (int index = 0; index < globalNames.size(); index++) {
      writeField(output, globalNames.get(index));
      writeLong(output, globalValues.get(index));
    }
    writeShort(output, value.measurements().size());
    value.measurements().forEach(item -> writeLong(output, item));
    writeShort(output, value.jobs().size());
    value.jobs().forEach(item -> writeField(output, item));
    writeLong(output, value.workflowSteps());
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(value.output().length).array());
    output.writeBytes(value.output());
    return output.toByteArray();
  }

  private static void writeField(ByteArrayOutputStream output, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    writeShort(output, bytes.length);
    output.writeBytes(bytes);
  }

  private static void writeShort(ByteArrayOutputStream output, int value) {
    output.writeBytes(ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) value).array());
  }

  private static void writeLong(ByteArrayOutputStream output, long value) {
    output.writeBytes(ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN)
        .putLong(value).array());
  }

  private static void field(MessageDigest digest, String value) {
    bytes(digest, value.getBytes(StandardCharsets.UTF_8));
  }

  private static void bytes(MessageDigest digest, byte[] value) {
    integer(digest, value.length);
    digest.update(value);
  }

  private static void integer(MessageDigest digest, long value) {
    digest.update(ByteBuffer.allocate(8).putLong(value).array());
  }

  private static void assertRejected(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 32);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[32], machine.hostOutput());
  }

  private static byte[] execute(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 32);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }

  private static synchronized Program program() throws Exception {
    if (compiledProgram != null) {
      return compiledProgram;
    }
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put(
        "TestExecutionIdentity.w",
        Files.readString(Path.of(
            "../wheeler-runtime/src/main/wheeler/runtime/testing/TestExecutionIdentity.w")));
    sources.put(
        "NativeTestExecutionIdentity.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestExecutionIdentity.w")));
    compiledProgram = new WheelerCompiler().compileModuleFiles(
        sources, "wheeler.conformance.testing.native_test_execution_identity");
    return compiledProgram;
  }

  private record Execution(
      String program,
      int kind,
      Map<String, Long> globals,
      List<Long> measurements,
      List<String> jobs,
      long workflowSteps,
      byte[] output
  ) {}
}
