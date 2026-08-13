package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Explicit semantic-tick deadline that requests cancellation without claiming no effect. */
public final class IoDeadline<T> {
  private final IoOperation<T> operation;
  private final long expiresAt;
  private boolean expired;

  public IoDeadline(IoOperation<T> operation, long expiresAt) {
    this.operation = Objects.requireNonNull(operation, "operation");
    if (expiresAt < 0) {
      throw new IllegalArgumentException("I/O deadline tick cannot be negative");
    }
    this.expiresAt = expiresAt;
  }

  /** Requests cancellation once the explicit caller-owned clock reaches the deadline. */
  public boolean expireAt(long currentTick) {
    if (currentTick < 0) {
      throw new IllegalArgumentException("I/O clock tick cannot be negative");
    }
    if (expired || currentTick < expiresAt) {
      return false;
    }
    expired = true;
    operation.cancel();
    return true;
  }

  public boolean expired() {
    return expired;
  }
}
