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
import org.junit.jupiter.api.Test;

/** Native evidence for one-case profile-2 semantic report identities. */
final class NativeTestReportIdentityExampleTest {
  private static final String RUNNER = identityText(1);
  private static final String CASE = identityText(2);
  private static final String SOURCE = identityText(3);
  private static final String ARTIFACT = identityText(4);
  private static final String EXECUTION = identityText(5);
  private static final String COVERAGE = identityText(6);
  private static Program compiledProgram;

  @Test
  void reproducesTheEmptyStageZeroReport() throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    field(digest, "wheeler.test-report/2");
    field(digest, RUNNER);
    integer(digest, 0);

    assertArrayEquals(digest.digest(), execute(emptyFrame()));
  }

  @Test
  void reproducesPassingAndFailingStageZeroReports() throws Exception {
    ReportCase pass = new ReportCase(
        "wheeler.compiler", "0.1.0", "self::compiles[0]", CASE, SOURCE,
        ARTIFACT, 0, "", "", 3, 44, EXECUTION, COVERAGE);
    ReportCase fail = new ReportCase(
        "wheeler.compiler", "0.1.0", "self::rejects", CASE, SOURCE,
        "", 1, "WTEST002", "runtime trap α", 1, 0, "", "");

    assertArrayEquals(expected(pass), execute(frame(pass)));
    assertArrayEquals(expected(fail), execute(frame(fail)));
  }

  @Test
  void rejectsIncompleteRowsBeforePublication() throws Exception {
    ReportCase passWithDiagnostic = new ReportCase(
        "pkg", "1", "target", CASE, SOURCE, ARTIFACT, 0,
        "WTEST003", "failed", 1, 1, EXECUTION, "");
    ReportCase failWithoutCode = new ReportCase(
        "pkg", "1", "target", CASE, SOURCE, "", 1,
        "", "failed", 1, 0, "", "");
    ReportCase negativeAssertions = new ReportCase(
        "pkg", "1", "target", CASE, SOURCE, ARTIFACT, 0,
        "", "", -1, 1, EXECUTION, "");

    assertRejected(frame(passWithDiagnostic));
    assertRejected(frame(failWithoutCode));
    assertRejected(frame(negativeAssertions));
  }

  private static byte[] expected(ReportCase value) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    field(digest, "wheeler.test-report/2");
    field(digest, RUNNER);
    integer(digest, 1);
    field(digest, value.packageName());
    field(digest, value.packageVersion());
    field(digest, value.targetName());
    field(digest, value.caseIdentity());
    field(digest, value.sourceIdentity());
    field(digest, value.artifactIdentity());
    field(digest, value.status() == 0 ? "PASS" : "FAIL");
    field(digest, value.diagnosticCode());
    field(digest, value.diagnosticMessage());
    integer(digest, value.assertions());
    integer(digest, value.workflowSteps());
    field(digest, value.executionIdentity());
    field(digest, value.coverageIdentity());
    return digest.digest();
  }

  private static byte[] emptyFrame() {
    byte[] runner = RUNNER.getBytes(StandardCharsets.US_ASCII);
    return ByteBuffer.allocate(2 + runner.length)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) runner.length)
        .put(runner)
        .array();
  }

  private static byte[] frame(ReportCase value) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    for (String field : List.of(
        RUNNER,
        value.packageName(),
        value.packageVersion(),
        value.targetName(),
        value.caseIdentity(),
        value.sourceIdentity(),
        value.artifactIdentity(),
        value.diagnosticCode(),
        value.diagnosticMessage(),
        value.executionIdentity(),
        value.coverageIdentity())) {
      byte[] bytes = field.getBytes(StandardCharsets.UTF_8);
      output.writeBytes(ByteBuffer.allocate(2)
          .order(ByteOrder.LITTLE_ENDIAN)
          .putShort((short) bytes.length)
          .array());
      output.writeBytes(bytes);
    }
    output.write(value.status());
    output.writeBytes(ByteBuffer.allocate(16)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putLong(value.assertions())
        .putLong(value.workflowSteps())
        .array());
    return output.toByteArray();
  }

  private static void field(MessageDigest digest, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    integer(digest, bytes.length);
    digest.update(bytes);
  }

  private static void integer(MessageDigest digest, long value) {
    digest.update(ByteBuffer.allocate(8).putLong(value).array());
  }

  private static String identityText(int value) {
    return "%064x".formatted(value);
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
        "TestReportIdentity.w",
        Files.readString(Path.of(
            "../wheeler-runtime/src/main/wheeler/runtime/testing/TestReportIdentity.w")));
    sources.put(
        "NativeTestReportIdentity.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestReportIdentity.w")));
    compiledProgram = new WheelerCompiler().compileModuleFiles(
        sources, "wheeler.conformance.testing.native_test_report_identity");
    return compiledProgram;
  }

  private record ReportCase(
      String packageName,
      String packageVersion,
      String targetName,
      String caseIdentity,
      String sourceIdentity,
      String artifactIdentity,
      int status,
      String diagnosticCode,
      String diagnosticMessage,
      long assertions,
      long workflowSteps,
      String executionIdentity,
      String coverageIdentity) {}
}
