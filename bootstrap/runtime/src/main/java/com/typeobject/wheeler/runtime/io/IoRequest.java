package com.typeobject.wheeler.runtime.io;

import java.nio.charset.StandardCharsets;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BooleanSupplier;

/** Pure prepared operation description consumed by exactly one submission path. */
public final class IoRequest<T> {
  /** Replaceable provider action invoked only after submission. */
  @FunctionalInterface
  public interface Action<T> {
    IoProviderResult<T> execute();
  }

  /** Provider cancellation signal used only after work has started. */
  @FunctionalInterface
  public interface Cancellation {
    void request();
  }

  private final String identity;
  private final long work;
  private final Action<T> action;
  private final Runnable release;
  private final Cancellation cancellation;
  private final BooleanSupplier readiness;
  private final AtomicBoolean consumed = new AtomicBoolean();
  private final AtomicBoolean released = new AtomicBoolean();

  private IoRequest(
      String identity,
      long work,
      Action<T> action,
      Runnable release,
      Cancellation cancellation,
      BooleanSupplier readiness) {
    this.identity = validateIdentity(identity);
    if (work < 1 || work > 1_000_000_000L) {
      throw new IllegalArgumentException("request work must be between 1 and 1000000000");
    }
    this.work = work;
    this.action = Objects.requireNonNull(action, "action");
    this.release = Objects.requireNonNull(release, "release");
    this.cancellation = Objects.requireNonNull(cancellation, "cancellation");
    this.readiness = Objects.requireNonNull(readiness, "readiness");
  }

  /** Constructs a request without invoking its provider action. */
  public static <T> IoRequest<T> prepare(String identity, long work, Action<T> action) {
    return prepare(identity, work, action, () -> {});
  }

  /** Constructs a request that releases captured resources at terminal completion. */
  public static <T> IoRequest<T> prepare(
      String identity, long work, Action<T> action, Runnable release) {
    return prepare(identity, work, action, release, () -> {});
  }

  /** Constructs a request with terminal release and started-work cancellation hooks. */
  public static <T> IoRequest<T> prepare(
      String identity,
      long work,
      Action<T> action,
      Runnable release,
      Cancellation cancellation) {
    return new IoRequest<>(identity, work, action, release, cancellation, () -> true);
  }

  /** Constructs a request whose readiness backend uses one explicit level signal. */
  public static <T> IoRequest<T> prepareWhen(
      String identity,
      long work,
      BooleanSupplier readiness,
      Action<T> action,
      Runnable release) {
    return new IoRequest<>(identity, work, action, release, () -> {}, readiness);
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

  boolean isReady() {
    return readiness.getAsBoolean();
  }

  IoProviderResult<T> execute() {
    return Objects.requireNonNull(action.execute(), "provider result");
  }

  void requestCancellation() {
    cancellation.request();
  }

  void releaseResources() {
    if (!released.compareAndSet(false, true)) {
      throw new IllegalStateException("request resources released more than once: " + identity);
    }
    release.run();
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
