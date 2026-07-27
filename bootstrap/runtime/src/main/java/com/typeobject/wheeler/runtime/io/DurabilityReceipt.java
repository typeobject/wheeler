package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Runtime-issued visibility or durability evidence; construction is not a public API. */
public final class DurabilityReceipt {
  /** Ordered file-publication stages; no stage can be obtained by casting. */
  public enum Kind {
    WRITE_COMPLETED,
    DATA_STABLE,
    FILE_STABLE,
    NAMESPACE_VISIBLE,
    NAMESPACE_STABLE,
    QUORUM_STABLE
  }

  private final Kind kind;
  private final DurabilitySubject subject;
  private final DurabilityProfile profile;
  private final DurabilityEvidence evidence;
  private final String parentIdentity;
  private final String identity;
  private final int depth;

  DurabilityReceipt(
      Kind kind,
      DurabilitySubject subject,
      DurabilityProfile profile,
      DurabilityEvidence evidence,
      String parentIdentity,
      String identity,
      int depth) {
    this.kind = Objects.requireNonNull(kind, "kind");
    this.subject = Objects.requireNonNull(subject, "subject");
    this.profile = Objects.requireNonNull(profile, "profile");
    this.evidence = Objects.requireNonNull(evidence, "evidence");
    this.parentIdentity = parentIdentity.equals("-")
        ? parentIdentity
        : DurabilitySubject.sha256("parentIdentity", parentIdentity);
    this.identity = DurabilitySubject.sha256("identity", identity);
    if (depth < 1 || depth > Kind.values().length) {
      throw new IllegalArgumentException("durability receipt depth is invalid");
    }
    this.depth = depth;
  }

  /** Returns the exact visibility or durability stage. */
  public Kind kind() {
    return kind;
  }

  /** Returns the protected subject shared by the complete chain. */
  public DurabilitySubject subject() {
    return subject;
  }

  /** Returns the failure, atomicity, replication, and assumption profile. */
  public DurabilityProfile profile() {
    return profile;
  }

  /** Returns the evidence accepted for this transition. */
  public DurabilityEvidence evidence() {
    return evidence;
  }

  /** Returns the prior receipt identity or `-` for initial completion. */
  public String parentIdentity() {
    return parentIdentity;
  }

  /** Returns the canonical content-derived receipt identity. */
  public String identity() {
    return identity;
  }

  /** Returns the one-based monotonic chain depth. */
  public int depth() {
    return depth;
  }
}
