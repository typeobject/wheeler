package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.runtime.ExecutionResult;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/** Canonical stage-0 result model for exact package test targets. */
final class TestReport {
  private static final int MAX_CASES = 65_535;
  private static final int MAX_DIAGNOSTIC_CHARS = 4_096;
  private final List<CaseResult> cases;
  private final String identity;

  TestReport(List<CaseResult> cases) throws IOException {
    if (cases.size() > MAX_CASES) {
      throw new IllegalArgumentException("Test report exceeds 65,535 cases");
    }
    List<CaseResult> sorted = new ArrayList<>(List.copyOf(cases));
    sorted.sort(Comparator.comparing(CaseResult::caseIdentity));
    Set<String> identities = new HashSet<>();
    for (CaseResult result : sorted) {
      if (!identities.add(result.caseIdentity())) {
        throw new IllegalArgumentException("Duplicate test case " + result.caseIdentity());
      }
    }
    this.cases = List.copyOf(sorted);
    String runnerIdentity = Stage0CompilerIdentity.current();
    identity = digest(digest -> {
      field(digest, "wheeler.test-report/1");
      field(digest, runnerIdentity);
      integer(digest, sorted.size());
      sorted.forEach(result -> result.digestInto(digest));
    });
  }

  static TestReport combine(List<TestReport> reports) throws IOException {
    List<CaseResult> cases = new ArrayList<>();
    reports.forEach(report -> cases.addAll(report.cases));
    return new TestReport(cases);
  }

  List<CaseResult> cases() {
    return cases;
  }

  int selected() {
    return cases.size();
  }

  int passed() {
    return (int) cases.stream().filter(result -> result.status() == Status.PASS).count();
  }

  int failed() {
    return selected() - passed();
  }

  boolean successful() {
    return failed() == 0;
  }

  String identity() {
    return identity;
  }

  static String caseIdentity(
      String manifestIdentity, String targetName, String sourceIdentity) {
    return digest(digest -> {
      field(digest, "wheeler.test-case/1");
      field(digest, manifestIdentity);
      field(digest, targetName);
      field(digest, sourceIdentity);
    });
  }

  static CaseResult pass(
      String packageName,
      String packageVersion,
      String targetName,
      String caseIdentity,
      String sourceIdentity,
      String artifactIdentity,
      ExecutionResult execution,
      String coverageIdentity) {
    return new CaseResult(
        packageName,
        packageVersion,
        targetName,
        caseIdentity,
        sourceIdentity,
        artifactIdentity,
        Status.PASS,
        "",
        "",
        execution.workflowSteps(),
        executionIdentity(execution),
        coverageIdentity);
  }

  static CaseResult fail(
      String packageName,
      String packageVersion,
      String targetName,
      String caseIdentity,
      String sourceIdentity,
      String artifactIdentity,
      String diagnosticCode,
      String diagnosticMessage) {
    return new CaseResult(
        packageName,
        packageVersion,
        targetName,
        caseIdentity,
        sourceIdentity,
        artifactIdentity,
        Status.FAIL,
        diagnosticCode,
        boundedDiagnostic(diagnosticMessage),
        0,
        "",
        "");
  }

  private static String executionIdentity(ExecutionResult result) {
    return digest(digest -> {
      field(digest, "wheeler.test-execution/1");
      field(digest, result.program());
      field(digest, result.kind().name());
      Map<String, Long> globals = new TreeMap<>(result.globals());
      integer(digest, globals.size());
      globals.forEach((name, value) -> {
        field(digest, name);
        signed(digest, value);
      });
      integer(digest, result.measurements().size());
      result.measurements().forEach(value -> signed(digest, value));
      integer(digest, result.quantumJobs().size());
      result.quantumJobs().forEach(job -> field(digest, job));
      signed(digest, result.workflowSteps());
      bytes(digest, result.output());
    });
  }

  private static String boundedDiagnostic(String message) {
    if (message == null) {
      return "unspecified test failure";
    }
    String normalized = message.replace('\r', ' ').replace('\n', ' ');
    return normalized.length() <= MAX_DIAGNOSTIC_CHARS
        ? normalized : normalized.substring(0, MAX_DIAGNOSTIC_CHARS);
  }

  private static String digest(DigestWriter writer) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      writer.write(digest);
      return HexFormat.of().formatHex(digest.digest());
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
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

  private static void signed(MessageDigest digest, long value) {
    integer(digest, value);
  }

  enum Status {
    PASS,
    FAIL
  }

  record CaseResult(
      String packageName,
      String packageVersion,
      String targetName,
      String caseIdentity,
      String sourceIdentity,
      String artifactIdentity,
      Status status,
      String diagnosticCode,
      String diagnosticMessage,
      long workflowSteps,
      String executionIdentity,
      String coverageIdentity) {
    CaseResult {
      if (packageName == null || packageVersion == null || targetName == null
          || !hex(caseIdentity) || !hex(sourceIdentity)
          || !artifactIdentity.isEmpty() && !hex(artifactIdentity)
          || status == null || diagnosticCode == null || diagnosticMessage == null
          || workflowSteps < 0 || executionIdentity == null || coverageIdentity == null
          || !executionIdentity.isEmpty() && !hex(executionIdentity)
          || !coverageIdentity.isEmpty() && !hex(coverageIdentity)) {
        throw new IllegalArgumentException("Invalid test case result");
      }
      if (status == Status.PASS
          && (!diagnosticCode.isEmpty() || !diagnosticMessage.isEmpty()
              || artifactIdentity.isEmpty() || executionIdentity.isEmpty())) {
        throw new IllegalArgumentException("Passing test result is incomplete");
      }
      if (status == Status.FAIL && diagnosticCode.isEmpty()) {
        throw new IllegalArgumentException("Failing test result requires a diagnostic");
      }
    }

    private void digestInto(MessageDigest digest) {
      field(digest, packageName);
      field(digest, packageVersion);
      field(digest, targetName);
      field(digest, caseIdentity);
      field(digest, sourceIdentity);
      field(digest, artifactIdentity);
      field(digest, status.name());
      field(digest, diagnosticCode);
      field(digest, diagnosticMessage);
      signed(digest, workflowSteps);
      field(digest, executionIdentity);
      field(digest, coverageIdentity);
    }

    private static boolean hex(String value) {
      return value != null && value.matches("[0-9a-f]{64}");
    }
  }

  @FunctionalInterface
  private interface DigestWriter {
    void write(MessageDigest digest);
  }
}
