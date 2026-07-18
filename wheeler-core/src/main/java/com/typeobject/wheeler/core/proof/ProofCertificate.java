package com.typeobject.wheeler.core.proof;

import java.util.Objects;

/** Canonical kernel-checkable claim tied to one exact program declaration. */
public record ProofCertificate(int id, String name, ProofRule rule, int subjectId) {
  public ProofCertificate {
    if (id < 0 || name == null || name.isBlank() || subjectId < 0) {
      throw new IllegalArgumentException("Invalid proof certificate");
    }
    Objects.requireNonNull(rule, "rule");
  }
}
