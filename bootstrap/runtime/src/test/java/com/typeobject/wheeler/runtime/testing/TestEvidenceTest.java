package com.typeobject.wheeler.runtime.testing;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.runtime.testing.TestEvidence.AssertionStatus;
import com.typeobject.wheeler.runtime.testing.TestEvidence.Kind;
import com.typeobject.wheeler.runtime.testing.TestEvidence.SampledComparison;
import com.typeobject.wheeler.runtime.testing.TestEvidence.Verdict;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Nominal assertion-reduction and sampled-evidence boundary tests. */
final class TestEvidenceTest {
  private static final String SUBJECT = "11".repeat(32);
  private static final String OBSERVATION = "22".repeat(32);

  @Test
  void reductionRetainsEveryNominalEvidenceKind() {
    for (Kind kind : Kind.values()) {
      List<String> identities = kind == Kind.SAMPLED_QUANTUM
          ? List.of(OBSERVATION) : List.of();
      TestEvidence evidence = new TestEvidence(
          kind, Verdict.SATISFIED, SUBJECT, identities, "");

      assertEquals(kind, evidence.resolve().kind());
      assertEquals(AssertionStatus.PASS, evidence.resolve().status());
    }
  }

  @Test
  void sampledInconclusiveCannotPassWithoutExplicitComparison() {
    TestEvidence sampled = new TestEvidence(
        Kind.SAMPLED_QUANTUM,
        Verdict.INCONCLUSIVE,
        SUBJECT,
        List.of(OBSERVATION),
        "shot bound exhausted");

    assertEquals(AssertionStatus.INCONCLUSIVE, sampled.resolve().status());
    TestEvidence compared = sampled.compareSampled(
        new SampledComparison("33".repeat(32), true));
    assertEquals(Kind.SAMPLED_QUANTUM, compared.resolve().kind());
    assertEquals(AssertionStatus.PASS, compared.resolve().status());
  }

  @Test
  void malformedEvidenceAndImplicitCrossKindComparisonFailClosed() {
    assertThrows(
        IllegalArgumentException.class,
        () -> new TestEvidence(
            Kind.SAMPLED_QUANTUM, Verdict.SATISFIED, SUBJECT, List.of(), ""));
    assertThrows(
        IllegalArgumentException.class,
        () -> new TestEvidence(
            Kind.PROOF, Verdict.INCONCLUSIVE, SUBJECT, List.of(), ""));
    TestEvidence exact = new TestEvidence(
        Kind.EXACT_QUANTUM, Verdict.SATISFIED, SUBJECT, List.of(), "");
    assertThrows(
        IllegalStateException.class,
        () -> exact.compareSampled(new SampledComparison("44".repeat(32), true)));
    String[] duplicates = new String[2];
    Arrays.fill(duplicates, OBSERVATION);
    assertThrows(
        IllegalArgumentException.class,
        () -> new TestEvidence(
            Kind.SAMPLED_QUANTUM,
            Verdict.SATISFIED,
            SUBJECT,
            List.of(duplicates),
            ""));
  }
}
