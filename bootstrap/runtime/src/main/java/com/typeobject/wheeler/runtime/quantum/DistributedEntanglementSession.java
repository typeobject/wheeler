package com.typeobject.wheeler.runtime.quantum;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Bounded network-entanglement session with delayed heralding and branch discard. */
public final class DistributedEntanglementSession {
  public enum State {
    REQUESTED,
    HERALDED,
    EXPIRED,
    DISCARDED
  }

  /** Persisted session state without provider or qubit handles. */
  public record Snapshot(
      String sessionIdentity,
      String leftEndpoint,
      String rightEndpoint,
      long requestedCycle,
      long deadlineCycle,
      State state,
      String heraldIdentity,
      String branchIdentity) {
    public Snapshot {
      if (!lowerHex(sessionIdentity) || !visible(leftEndpoint) || !visible(rightEndpoint)
          || leftEndpoint.compareTo(rightEndpoint) >= 0
          || requestedCycle < 0 || deadlineCycle < requestedCycle
          || state == null || heraldIdentity == null || branchIdentity == null
          || !heraldIdentity.equals("-") && !lowerHex(heraldIdentity)
          || !lowerHex(branchIdentity)) {
        throw new IllegalArgumentException("distributed session snapshot is invalid");
      }
    }
  }

  private final String leftEndpoint;
  private final String rightEndpoint;
  private final long requestedCycle;
  private final long deadlineCycle;
  private final String sessionIdentity;
  private State state = State.REQUESTED;
  private String heraldIdentity = "-";
  private String branchIdentity;

  private DistributedEntanglementSession(
      String leftEndpoint, String rightEndpoint, long requestedCycle, long deadlineCycle) {
    this.leftEndpoint = leftEndpoint;
    this.rightEndpoint = rightEndpoint;
    this.requestedCycle = requestedCycle;
    this.deadlineCycle = deadlineCycle;
    sessionIdentity = digest("wheeler-entanglement-session-1\n" + leftEndpoint + '\n'
        + rightEndpoint + '\n' + requestedCycle + '\n' + deadlineCycle + '\n');
    branchIdentity = branch(State.REQUESTED, "-");
  }

  /** Starts one ordered endpoint session after explicit network capability admission. */
  public static DistributedEntanglementSession request(
      TargetDescriptor descriptor,
      String firstEndpoint,
      String secondEndpoint,
      long requestedCycle,
      long deadlineCycle) {
    Objects.requireNonNull(descriptor, "descriptor")
        .require(TargetCapability.NETWORK_ENTANGLEMENT);
    if (!visible(firstEndpoint) || !visible(secondEndpoint)
        || firstEndpoint.equals(secondEndpoint)
        || requestedCycle < 0 || deadlineCycle < requestedCycle) {
      throw new IllegalArgumentException("distributed session request is invalid");
    }
    String left = firstEndpoint.compareTo(secondEndpoint) < 0 ? firstEndpoint : secondEndpoint;
    String right = firstEndpoint.compareTo(secondEndpoint) < 0 ? secondEndpoint : firstEndpoint;
    return new DistributedEntanglementSession(left, right, requestedCycle, deadlineCycle);
  }

  /** Restores exact persisted state without requesting another network operation. */
  public static DistributedEntanglementSession restore(Snapshot snapshot) {
    Objects.requireNonNull(snapshot, "snapshot");
    DistributedEntanglementSession restored = new DistributedEntanglementSession(
        snapshot.leftEndpoint(),
        snapshot.rightEndpoint(),
        snapshot.requestedCycle(),
        snapshot.deadlineCycle());
    if (!restored.sessionIdentity.equals(snapshot.sessionIdentity())) {
      throw new IllegalArgumentException("distributed session identity mismatch");
    }
    restored.state = snapshot.state();
    restored.heraldIdentity = snapshot.heraldIdentity();
    restored.branchIdentity = snapshot.branchIdentity();
    if (!restored.branch(restored.state, restored.heraldIdentity)
        .equals(restored.branchIdentity)) {
      throw new IllegalArgumentException("distributed session branch mismatch");
    }
    return restored;
  }

  /** Accepts one delayed herald only while the exact request branch remains live. */
  public synchronized void herald(String evidenceIdentity, long cycle) {
    if (state != State.REQUESTED) {
      throw new IllegalStateException("distributed session is no longer awaiting heralding");
    }
    if (!lowerHex(evidenceIdentity) || cycle < requestedCycle || deadlineCycle < cycle) {
      throw new IllegalArgumentException("distributed herald evidence is invalid or late");
    }
    state = State.HERALDED;
    heraldIdentity = evidenceIdentity;
    branchIdentity = branch(state, heraldIdentity);
  }

  /** Expires an unheralded request without claiming destruction of remote entanglement. */
  public synchronized void expire(long cycle) {
    if (state != State.REQUESTED || cycle <= deadlineCycle) {
      throw new IllegalStateException("distributed session cannot expire at this cycle");
    }
    state = State.EXPIRED;
    branchIdentity = branch(state, "-");
  }

  /** Discards local use of a terminal branch without asserting a remote physical rollback. */
  public synchronized void discard() {
    if (state != State.HERALDED && state != State.EXPIRED) {
      throw new IllegalStateException("only a terminal distributed branch can be discarded");
    }
    state = State.DISCARDED;
    branchIdentity = branch(state, heraldIdentity);
  }

  public synchronized Snapshot snapshot() {
    return new Snapshot(
        sessionIdentity,
        leftEndpoint,
        rightEndpoint,
        requestedCycle,
        deadlineCycle,
        state,
        heraldIdentity,
        branchIdentity);
  }

  private String branch(State selected, String herald) {
    return digest("wheeler-entanglement-branch-1\n" + sessionIdentity + '\n'
        + selected.name() + '\n' + herald + '\n');
  }

  private static boolean visible(String value) {
    if (value == null || value.isBlank() || value.length() > 128 || !value.equals(value.trim())) {
      return false;
    }
    return value.chars().allMatch(character -> character >= 0x21 && character <= 0x7e);
  }

  private static boolean lowerHex(String value) {
    return value != null && value.length() == 64
        && value.chars().allMatch(character -> character >= '0' && character <= '9'
            || character >= 'a' && character <= 'f');
  }

  private static String digest(String canonical) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          canonical.getBytes(StandardCharsets.US_ASCII)));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
