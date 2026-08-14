package com.typeobject.wheeler.runtime.io;

import java.util.Objects;
import java.util.function.Function;

/** Provider result before the scope assigns lifecycle and cancellation facts. */
public record IoProviderResult<T>(Kind kind, T value, String detail, long progress) {
  /** Closed provider outcomes; completion and durability remain separate. */
  public enum Kind {
    SUCCESS,
    FAILURE,
    CANCELED_BEFORE_EFFECT,
    CANCELED_AFTER_PARTIAL_EFFECT,
    UNCERTAIN
  }

  public IoProviderResult {
    Objects.requireNonNull(kind, "kind");
    if (progress < 0) {
      throw new IllegalArgumentException("progress cannot be negative");
    }
    if (kind == Kind.CANCELED_BEFORE_EFFECT && progress != 0) {
      throw new IllegalArgumentException("pre-effect cancellation cannot report progress");
    }
    if (kind == Kind.CANCELED_AFTER_PARTIAL_EFFECT && progress == 0) {
      throw new IllegalArgumentException("partial cancellation needs positive progress");
    }
    if (kind == Kind.SUCCESS) {
      Objects.requireNonNull(value, "successful value");
      if (detail != null) {
        throw new IllegalArgumentException("successful result cannot carry error detail");
      }
    } else {
      if (value != null) {
        throw new IllegalArgumentException("non-success result cannot carry a value");
      }
      if (detail == null || detail.isBlank() || detail.length() > 256) {
        throw new IllegalArgumentException("non-success result needs bounded detail");
      }
    }
  }

  /** Maps only a successful value while preserving failure and progress semantics. */
  public <R> IoProviderResult<R> mapSuccess(Function<? super T, ? extends R> mapper) {
    Objects.requireNonNull(mapper, "mapper");
    return switch (kind) {
      case SUCCESS -> success(mapper.apply(value), progress);
      case FAILURE -> failure(detail, progress);
      case CANCELED_BEFORE_EFFECT -> canceledBeforeEffect(detail);
      case CANCELED_AFTER_PARTIAL_EFFECT -> canceledAfterPartial(detail, progress);
      case UNCERTAIN -> uncertain(detail, progress);
    };
  }

  /** Returns a successful provider result. */
  public static <T> IoProviderResult<T> success(T value, long progress) {
    return new IoProviderResult<>(Kind.SUCCESS, value, null, progress);
  }

  /** Returns a known provider failure. */
  public static <T> IoProviderResult<T> failure(String detail, long progress) {
    return new IoProviderResult<>(Kind.FAILURE, null, detail, progress);
  }

  /** Returns cancellation before any external effect. */
  public static <T> IoProviderResult<T> canceledBeforeEffect(String detail) {
    return new IoProviderResult<>(Kind.CANCELED_BEFORE_EFFECT, null, detail, 0);
  }

  /** Returns cancellation after known partial external progress. */
  public static <T> IoProviderResult<T> canceledAfterPartial(String detail, long progress) {
    return new IoProviderResult<>(Kind.CANCELED_AFTER_PARTIAL_EFFECT, null, detail, progress);
  }

  /** Returns an uncertain external outcome with reconciliation detail. */
  public static <T> IoProviderResult<T> uncertain(String detail, long progress) {
    return new IoProviderResult<>(Kind.UNCERTAIN, null, detail, progress);
  }
}
