package com.typeobject.wheeler.runtime.testing;

import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;

/** Bounded typed assertion evidence that cannot be promoted by presentation code. */
public record TestEvidence(
    Kind kind,
    Verdict verdict,
    String subjectIdentity,
    List<String> evidenceIdentities,
    String reason) {
  private static final int MAX_EVIDENCE = 64;
  private static final int MAX_REASON_SCALARS = 1_024;
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");

  public TestEvidence {
    Objects.requireNonNull(kind, "kind");
    Objects.requireNonNull(verdict, "verdict");
    subjectIdentity = identity(subjectIdentity, "test evidence subject");
    evidenceIdentities = List.copyOf(evidenceIdentities);
    if (evidenceIdentities.size() > MAX_EVIDENCE
        || evidenceIdentities.stream().anyMatch(value -> !IDENTITY.matcher(value).matches())
        || evidenceIdentities.stream().distinct().count() != evidenceIdentities.size()) {
      throw new IllegalArgumentException("Invalid test evidence identities");
    }
    Objects.requireNonNull(reason, "reason");
    if (reason.codePointCount(0, reason.length()) > MAX_REASON_SCALARS) {
      throw new IllegalArgumentException("Test evidence reason exceeds 1,024 scalars");
    }
    if (verdict == Verdict.INCONCLUSIVE && reason.isBlank()) {
      throw new IllegalArgumentException("Inconclusive evidence requires a reason");
    }
    if (kind == Kind.SAMPLED_QUANTUM && evidenceIdentities.isEmpty()) {
      throw new IllegalArgumentException("Sampled evidence requires an observation identity");
    }
  }

  /** Resolves one typed assertion without changing the evidence kind. */
  public AssertionResolution resolve() {
    return switch (verdict) {
      case SATISFIED -> new AssertionResolution(kind, AssertionStatus.PASS, subjectIdentity);
      case REFUTED -> new AssertionResolution(kind, AssertionStatus.FAIL, subjectIdentity);
      case INCONCLUSIVE -> new AssertionResolution(kind, AssertionStatus.INCONCLUSIVE, subjectIdentity);
    };
  }

  /** Converts sampled evidence only through an explicit reviewed statistical comparison. */
  public TestEvidence compareSampled(SampledComparison comparison) {
    if (kind != Kind.SAMPLED_QUANTUM) {
      throw new IllegalStateException("Statistical comparison requires sampled quantum evidence");
    }
    Objects.requireNonNull(comparison, "comparison");
    Verdict compared = comparison.accepted()
        ? Verdict.SATISFIED : Verdict.REFUTED;
    return new TestEvidence(
        Kind.SAMPLED_QUANTUM,
        compared,
        subjectIdentity,
        evidenceIdentities,
        "comparison:" + comparison.identity());
  }

  private static String identity(String value, String description) {
    if (value == null || !IDENTITY.matcher(value).matches()) {
      throw new IllegalArgumentException("Invalid SHA-256 identity for " + description);
    }
    return value;
  }

  /** Nominal evidence contracts retained by assertion reduction. */
  public enum Kind {
    CLASSICAL,
    LANGUAGE_INVERSE,
    VM_REWIND,
    UNCOMPUTATION,
    EXACT_QUANTUM,
    SAMPLED_QUANTUM,
    WORKFLOW,
    PACKAGE,
    PROOF,
    MALFORMED_ARTIFACT
  }

  public enum Verdict {
    SATISFIED,
    REFUTED,
    INCONCLUSIVE
  }

  public enum AssertionStatus {
    PASS,
    FAIL,
    INCONCLUSIVE
  }

  public record AssertionResolution(
      Kind kind, AssertionStatus status, String subjectIdentity) {
    public AssertionResolution {
      Objects.requireNonNull(kind, "kind");
      Objects.requireNonNull(status, "status");
      identity(subjectIdentity, "assertion subject");
    }
  }

  public record SampledComparison(String identity, boolean accepted) {
    public SampledComparison {
      TestEvidence.identity(identity, "sampled comparison");
    }
  }
}
