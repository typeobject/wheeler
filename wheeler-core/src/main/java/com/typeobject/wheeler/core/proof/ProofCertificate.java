package com.typeobject.wheeler.core.proof;

import java.util.Objects;

/** Canonical kernel-checkable claim tied to one exact program declaration. */
public record ProofCertificate(
    int id, String name, ProofRule rule, int subjectId, long argument) {
  public ProofCertificate {
    if (id < 0 || name == null || name.isBlank() || subjectId < 0) {
      throw new IllegalArgumentException("Invalid proof certificate");
    }
    Objects.requireNonNull(rule, "rule");
    switch (rule) {
      case GENERATED_INVERSE, GENERATED_ADJOINT -> {
        if (argument != -1) {
          throw new IllegalArgumentException("Invalid unary proof argument");
        }
      }
      case CIRCUIT_EQUIVALENCE -> {
        if (argument < 0 || argument > 65_535) {
          throw new IllegalArgumentException("Invalid related circuit ID");
        }
      }
      case STATIC_STEP_BOUND -> {
        if (argument <= 0) {
          throw new IllegalArgumentException("Invalid step bound");
        }
      }
    }
  }
}
