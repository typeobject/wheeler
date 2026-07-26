package com.typeobject.wheeler.runtime.io;

import java.nio.charset.StandardCharsets;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;

/** Pure prepared operation description consumed by exactly one submission path. */
public final class IoRequest<T> {
  /** Replaceable provider action invoked only after submission. */
  @FunctionalInterface
  public interface Action<T> {
    IoTaskResult<T> execute();
  }

  private final String identity;
  private final long work;
  private final Action<T> action;
  private final AtomicBoolean consumed = new AtomicBoolean();

  private IoRequest(String identity, long work, Action<T> action) {
    this.identity = validateIdentity(identity);
    if (work < 1 || work > 1_000_000_000L) {
      throw new IllegalArgumentException("request work must be between 1 and 1000000000");
    }
    this.work = work;
    this.action = Objects.requireNonNull(action, "action");
  }

  /** Constructs a request without invoking its provider action. */
  public static <T> IoRequest<T> prepare(String identity, long work, Action<T> action) {
    return new IoRequest<>(identity, work, action);
  }

  /** Returns the stable request identity. */
  public String identity() {
    return identity;
  }

  /** Returns the declared work charged before submission. */
  public long work() {
    return work;
  }

  boolean isConsumed() {
    return consumed.get();
  }

  void consume() {
    if (!consumed.compareAndSet(false, true)) {
      throw new IllegalStateException("request was already consumed: " + identity);
    }
  }

  IoTaskResult<T> execute() {
    return Objects.requireNonNull(action.execute(), "provider result");
  }

  private static String validateIdentity(String identity) {
    Objects.requireNonNull(identity, "identity");
    int bytes = identity.getBytes(StandardCharsets.UTF_8).length;
    if (identity.isBlank() || bytes > 256 || !identity.equals(identity.trim())) {
      throw new IllegalArgumentException("request identity must be 1..256 canonical UTF-8 bytes");
    }
    for (int index = 0; index < identity.length(); index++) {
      char value = identity.charAt(index);
      if (value < 0x21 || value > 0x7e) {
        throw new IllegalArgumentException("request identity must use visible ASCII");
      }
    }
    return identity;
  }
}
