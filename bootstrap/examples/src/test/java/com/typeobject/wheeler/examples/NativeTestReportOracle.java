package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.runtime.ExecutionResult;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.TreeMap;

/** Independent JVM encodings of the native case, execution, and report identity schemas. */
final class NativeTestReportOracle {
  record ReportCase(
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

  private NativeTestReportOracle() {}

  static String caseIdentity(String manifest, String source, String name) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    field(digest, "wheeler.test-case/1");
    field(digest, manifest);
    field(digest, name);
    field(digest, source);
    return HexFormat.of().formatHex(digest.digest());
  }

  static String executionIdentity(ExecutionResult result) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    field(digest, "wheeler.test-execution/1");
    field(digest, result.program());
    field(digest, result.kind().name());
    integer(digest, result.globals().size());
    new TreeMap<>(result.globals()).forEach((name, value) -> {
      field(digest, name);
      integer(digest, value);
    });
    integer(digest, result.measurements().size());
    result.measurements().forEach(value -> integer(digest, value));
    integer(digest, result.quantumJobs().size());
    result.quantumJobs().forEach(job -> field(digest, job));
    integer(digest, result.workflowSteps());
    bytes(digest, result.output());
    return HexFormat.of().formatHex(digest.digest());
  }

  static byte[] reportIdentity(String runner, List<ReportCase> cases) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    field(digest, "wheeler.test-report/2");
    field(digest, runner);
    integer(digest, cases.size());
    for (ReportCase value : cases.stream()
        .sorted(Comparator.comparing(ReportCase::caseIdentity)).toList()) {
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
    }
    return digest.digest();
  }

  static byte[] summary(String runner, List<ReportCase> cases) throws Exception {
    int passed = (int) cases.stream().filter(value -> value.status() == 0).count();
    return ByteBuffer.allocate(39).order(ByteOrder.LITTLE_ENDIAN)
        .put(reportIdentity(runner, cases))
        .putShort((short) cases.size())
        .putShort((short) passed)
        .putShort((short) (cases.size() - passed))
        .put((byte) (cases.size() == passed ? 1 : 0))
        .array();
  }

  private static void field(MessageDigest digest, String value) {
    bytes(digest, value.getBytes(StandardCharsets.UTF_8));
  }

  private static void bytes(MessageDigest digest, byte[] value) {
    integer(digest, value.length);
    digest.update(value);
  }

  private static void integer(MessageDigest digest, long value) {
    digest.update(ByteBuffer.allocate(Long.BYTES).putLong(value).array());
  }
}
