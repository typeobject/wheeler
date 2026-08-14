package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Explicit VM rewind horizon established when a live I/O effect is accepted. */
public final class IoEffectBoundary {
  /** Live I/O and compensation remain distinct external effects. */
  public enum Kind {
    LIVE_IO,
    COMPENSATION
  }

  private final Kind kind;
  private final long operationId;
  private final String requestIdentity;
  private final String identity;

  private IoEffectBoundary(
      Kind kind, long operationId, String requestIdentity, String identity) {
    this.kind = kind;
    this.operationId = operationId;
    this.requestIdentity = requestIdentity;
    this.identity = identity;
  }

  /** Accepts one live terminal completion and cuts the VM rewind tail. */
  public static IoEffectBoundary acceptLive(
      VirtualMachine machine, IoCompletion<?> completion) {
    return accept(machine, completion, Kind.LIVE_IO);
  }

  static IoEffectBoundary acceptCompensation(
      VirtualMachine machine, IoCompletion<?> completion) {
    return accept(machine, completion, Kind.COMPENSATION);
  }

  public Kind kind() {
    return kind;
  }

  public long operationId() {
    return operationId;
  }

  public String requestIdentity() {
    return requestIdentity;
  }

  public String identity() {
    return identity;
  }

  private static IoEffectBoundary accept(
      VirtualMachine machine, IoCompletion<?> completion, Kind kind) {
    Objects.requireNonNull(machine, "machine");
    Objects.requireNonNull(completion, "completion");
    if (!completion.resourcesReleased()) {
      throw new IllegalArgumentException("I/O completion has not released its resources");
    }
    String canonical = kind + "\0" + completion.operationId() + "\0"
        + completion.requestIdentity() + "\0" + completion.terminalKind() + "\0"
        + completion.cancellationRelation() + "\0" + completion.progress() + "\0"
        + completion.declaredWork() + "\0" + completion.backend();
    String identity = sha256("wheeler-io-effect-boundary-1\0" + canonical);
    machine.establishEffectBoundary();
    return new IoEffectBoundary(
        kind, completion.operationId(), completion.requestIdentity(), identity);
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
