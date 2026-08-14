package com.typeobject.wheeler.core.proof;

import java.util.Objects;

/** Observer for proof lookup, obligation, rule, acceptance, and rejection stages. */
@FunctionalInterface
public interface ProofObserver {
  /** Distinct proof-kernel stages; no stage substitutes for another. */
  enum Stage {
    LOOKUP,
    OBLIGATION,
    RULE_EXECUTION,
    ACCEPTANCE,
    REJECTION
  }

  /** Immutable proof-kernel observation. */
  record Observation(
      long sequence,
      String certificate,
      ProofRule rule,
      int subjectId,
      Stage stage) {
    public Observation {
      if (sequence < 0 || subjectId < 0) {
        throw new IllegalArgumentException("proof observation coordinates must be nonnegative");
      }
      Objects.requireNonNull(certificate, "certificate");
      Objects.requireNonNull(rule, "rule");
      Objects.requireNonNull(stage, "stage");
    }
  }

  /** Receives one successful stage transition. */
  void observe(Observation observation);
}
