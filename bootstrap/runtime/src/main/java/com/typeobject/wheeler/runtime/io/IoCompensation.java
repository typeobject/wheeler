package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** A second external request that records compensation without claiming inverse execution. */
public final class IoCompensation {
  /** Runtime-issued successful compensation evidence. */
  public static final class Receipt {
    private final long originalOperationId;
    private final String originalRequestIdentity;
    private final String actionIdentity;
    private final String evidenceIdentity;
    private final String identity;

    private Receipt(
        long originalOperationId,
        String originalRequestIdentity,
        String actionIdentity,
        String evidenceIdentity,
        String identity) {
      this.originalOperationId = originalOperationId;
      this.originalRequestIdentity = originalRequestIdentity;
      this.actionIdentity = actionIdentity;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    public long originalOperationId() {
      return originalOperationId;
    }

    public String originalRequestIdentity() {
      return originalRequestIdentity;
    }

    public String actionIdentity() {
      return actionIdentity;
    }

    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    public String identity() {
      return identity;
    }
  }

  private IoCompensation() {}

  /** Prepares a distinct compensation request from one effect-bearing completion. */
  public static IoRequest<Receipt> prepare(
      IoCompletion<?> original,
      String actionIdentity,
      long work,
      IoRequest.Action<String> action) {
    Objects.requireNonNull(original, "original");
    String canonicalAction = visibleName(actionIdentity, "compensation action identity");
    Objects.requireNonNull(action, "action");
    if (original.cancellationRelation()
        == IoCompletion.CancellationRelation.CANCELED_BEFORE_EFFECT) {
      throw new IllegalArgumentException("effect-free cancellation cannot be compensated");
    }
    if (original.terminalKind() == IoCompletion.TerminalKind.FAILURE
        && original.progress() == 0) {
      throw new IllegalArgumentException("known effect-free failure cannot be compensated");
    }
    String requestIdentity = "io-compensate:" + original.operationId() + ':' + canonicalAction;
    return IoRequest.prepare(requestIdentity, work, () -> action.execute().mapSuccess(evidence -> {
      String canonicalEvidence = hash(evidence, "compensation evidence identity");
      String canonical = original.operationId() + "\0" + original.requestIdentity() + "\0"
          + canonicalAction + "\0" + canonicalEvidence;
      return new Receipt(
          original.operationId(),
          original.requestIdentity(),
          canonicalAction,
          canonicalEvidence,
          sha256("wheeler-io-compensation-1\0" + canonical));
    }));
  }

  /** Accepts successful compensation evidence and establishes a second VM effect boundary. */
  public static IoEffectBoundary accept(
      VirtualMachine machine, IoCompletion<Receipt> completion) {
    Objects.requireNonNull(completion, "completion");
    if (completion.terminalKind() != IoCompletion.TerminalKind.SUCCESS) {
      throw new IllegalArgumentException("only successful compensation can be accepted");
    }
    Receipt receipt = Objects.requireNonNull(completion.value(), "compensation receipt");
    String canonical = receipt.originalOperationId + "\0" + receipt.originalRequestIdentity + "\0"
        + receipt.actionIdentity + "\0" + receipt.evidenceIdentity;
    String expected = sha256("wheeler-io-compensation-1\0" + canonical);
    if (!expected.equals(receipt.identity)) {
      throw new IllegalArgumentException("compensation receipt identity mismatch");
    }
    return IoEffectBoundary.acceptCompensation(machine, completion);
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

  private static String hash(String value, String field) {
    Objects.requireNonNull(value, field);
    if (!value.matches("[0-9a-f]{64}")) {
      throw new IllegalArgumentException(field + " must be lowercase SHA-256");
    }
    return value;
  }

  private static String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          value.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
