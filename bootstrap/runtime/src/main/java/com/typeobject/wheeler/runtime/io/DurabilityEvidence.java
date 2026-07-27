package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Content-bound backend evidence accepted for exactly one durability transition. */
public record DurabilityEvidence(Source source, String evidenceIdentity, String detail) {
  /** Runtime-owned evidence acquisition source. */
  public enum Source {
    OPERATION_COMPLETION,
    DATA_FLUSH,
    METADATA_FLUSH,
    ATOMIC_RENAME,
    NAMESPACE_FLUSH,
    QUORUM_PROTOCOL
  }

  public DurabilityEvidence {
    Objects.requireNonNull(source, "source");
    evidenceIdentity = DurabilitySubject.sha256("evidenceIdentity", evidenceIdentity);
    detail = DurabilitySubject.visibleAscii("detail", detail, 256, false);
  }
}
