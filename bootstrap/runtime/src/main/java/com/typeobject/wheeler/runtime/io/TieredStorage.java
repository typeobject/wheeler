package com.typeobject.wheeler.runtime.io;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Bounded stage-0 tier placement and drain profile with affine source leases. */
public final class TieredStorage {
  private static final int MAX_PLACEMENT_BYTES = 16 * 1024 * 1024;

  /** Named placement target with one failure domain and capacity bound. */
  public record Tier(String name, String failureDomain, long capacity) {
    public Tier {
      name = visibleName(name, "tier");
      failureDomain = visibleName(failureDomain, "failure domain");
      if (capacity < 0 || capacity > MAX_PLACEMENT_BYTES) {
        throw new IllegalArgumentException("tier capacity must be between 0 and 16 MiB");
      }
    }
  }

  /** Transfer outcome. Partial failure preserves exact placement evidence. */
  public enum DrainOutcome {
    COMPLETE,
    PARTIAL_FAILURE
  }

  /** Typed result for a completed drain protocol. */
  public record DrainResult(
      DrainOutcome outcome,
      StagedData placement,
      long requestedBytes,
      boolean sourceRetained) {
    public DrainResult {
      Objects.requireNonNull(outcome, "outcome");
      Objects.requireNonNull(placement, "placement");
      if (requestedBytes < 0 || placement.bytes() > requestedBytes) {
        throw new IllegalArgumentException("drain result extent is invalid");
      }
      if ((outcome == DrainOutcome.COMPLETE) != (placement.bytes() == requestedBytes)) {
        throw new IllegalArgumentException("drain outcome disagrees with placed bytes");
      }
      if (!sourceRetained) {
        throw new IllegalArgumentException("drain result must retain its source placement");
      }
    }
  }

  /** Affine source placement retained through terminal drain resource release. */
  public static final class Placement {
    private final byte[] bytes;
    private final StagedData evidence;
    private boolean held;

    private Placement(byte[] bytes, StagedData evidence) {
      this.bytes = bytes;
      this.evidence = evidence;
    }

    /** Returns immutable placement evidence while the caller owns the lease. */
    public synchronized StagedData evidence() {
      requireOwned();
      return evidence;
    }

    /** Returns an independent byte snapshot while the caller owns the lease. */
    public synchronized byte[] snapshot() {
      requireOwned();
      return bytes.clone();
    }

    private synchronized void hold() {
      if (held) {
        throw new IllegalStateException("tier placement is already held by a drain");
      }
      held = true;
    }

    private synchronized void release() {
      if (!held) {
        throw new IllegalStateException("tier placement is not held by a drain");
      }
      held = false;
    }

    private synchronized byte[] heldPrefix(int length) {
      if (!held) {
        throw new IllegalStateException("drain accessed an unheld source placement");
      }
      byte[] prefix = new byte[length];
      System.arraycopy(bytes, 0, prefix, 0, length);
      return prefix;
    }

    private void requireOwned() {
      if (held) {
        throw new IllegalStateException("tier placement is held until terminal release");
      }
    }
  }

  private TieredStorage() {}

  /** Creates exact initial placement evidence from caller bytes. */
  public static Placement place(Tier tier, byte[] bytes) {
    Objects.requireNonNull(tier, "tier");
    Objects.requireNonNull(bytes, "bytes");
    if (bytes.length > tier.capacity()) {
      throw new IllegalArgumentException("placement exceeds tier capacity");
    }
    byte[] owned = bytes.clone();
    StagedData evidence = StagedData.initial(
        tier.name(), tier.failureDomain(), sha256(owned), owned.length);
    return new Placement(owned, evidence);
  }

  /**
   * Prepares a complete or deliberately bounded partial drain without moving its source lease.
   *
   * <p>The transfer limit models a provider's last known successful prefix. A shorter limit
   * returns {@link DrainOutcome#PARTIAL_FAILURE} with exact prefix evidence.
   */
  public static IoRequest<DrainResult> drain(
      Placement source, Tier target, int transferLimit) {
    Objects.requireNonNull(source, "source");
    Objects.requireNonNull(target, "target");
    StagedData sourceEvidence = source.evidence();
    if (sourceEvidence.bytes() > target.capacity()) {
      throw new IllegalArgumentException("drain exceeds target tier capacity");
    }
    if (transferLimit < 0 || transferLimit > sourceEvidence.bytes()) {
      throw new IllegalArgumentException("drain transfer limit is out of bounds");
    }
    source.hold();
    long work = Math.max(1, sourceEvidence.bytes());
    String requestIdentity = "tier-drain:" + sourceEvidence.identity() + ':' + target.name();
    try {
      return IoRequest.prepare(
          requestIdentity,
          work,
          () -> {
            byte[] placed = source.heldPrefix(transferLimit);
            StagedData evidence;
            DrainOutcome outcome;
            if (transferLimit == sourceEvidence.bytes()) {
              evidence = sourceEvidence.restage(target.name(), target.failureDomain());
              outcome = DrainOutcome.COMPLETE;
            } else {
              evidence = StagedData.partialOf(
                  sourceEvidence,
                  target.name(),
                  target.failureDomain(),
                  sha256(placed),
                  transferLimit);
              outcome = DrainOutcome.PARTIAL_FAILURE;
            }
            return IoProviderResult.success(
                new DrainResult(outcome, evidence, sourceEvidence.bytes(), true),
                transferLimit);
          },
          source::release);
    } catch (RuntimeException failure) {
      source.release();
      throw failure;
    }
  }

  private static String visibleName(String value, String field) {
    Objects.requireNonNull(value, field);
    if (value.isBlank() || value.length() > 128 || !value.equals(value.trim())) {
      throw new IllegalArgumentException(field + " must be 1..128 visible ASCII bytes");
    }
    for (int index = 0; index < value.length(); index++) {
      char scalar = value.charAt(index);
      if (scalar < 0x21 || scalar > 0x7e) {
        throw new IllegalArgumentException(field + " must use visible ASCII");
      }
    }
    return value;
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
