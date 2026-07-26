package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Provider result before the scope assigns lifecycle and cancellation facts. */
public record IoTaskResult<T>(Kind kind, T value, String detail, long progress) {
  /** Closed provider outcomes; completion and durability remain separate. */
  public enum Kind {
    SUCCESS,
    FAILURE,
    CANCELED_AFTER_PARTIAL_EFFECT,
    UNCERTAIN
  }

  public IoTaskResult {
    Objects.requireNonNull(kind, "kind");
    if (progress < 0) {
      throw new IllegalArgumentException("progress cannot be negative");
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

  /** Returns a successful provider result. */
  public static <T> IoTaskResult<T> success(T value, long progress) {
    return new IoTaskResult<>(Kind.SUCCESS, value, null, progress);
  }

  /** Returns a known provider failure. */
  public static <T> IoTaskResult<T> failure(String detail, long progress) {
    return new IoTaskResult<>(Kind.FAILURE, null, detail, progress);
  }

  /** Returns cancellation after known partial external progress. */
  public static <T> IoTaskResult<T> canceledAfterPartial(String detail, long progress) {
    return new IoTaskResult<>(Kind.CANCELED_AFTER_PARTIAL_EFFECT, null, detail, progress);
  }

  /** Returns an uncertain external outcome with reconciliation detail. */
  public static <T> IoTaskResult<T> uncertain(String detail, long progress) {
    return new IoTaskResult<>(Kind.UNCERTAIN, null, detail, progress);
  }
}
