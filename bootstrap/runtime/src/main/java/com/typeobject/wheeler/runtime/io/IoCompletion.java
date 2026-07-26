package com.typeobject.wheeler.runtime.io;

import java.util.Objects;
import java.util.Optional;

/** Exact terminal lifecycle fact; this type makes no durability claim. */
public record IoCompletion<T>(
    long operationId,
    String requestIdentity,
    TerminalKind terminalKind,
    CancellationRelation cancellationRelation,
    T value,
    String detail,
    long progress,
    long declaredWork,
    boolean resourcesReleased,
    String backend) {
  /** Mutually exclusive terminal outcomes. */
  public enum TerminalKind {
    SUCCESS,
    FAILURE,
    CANCELED,
    UNCERTAIN
  }

  /** Exact relation between cancellation and terminal observation. */
  public enum CancellationRelation {
    NOT_REQUESTED,
    CANCELED_BEFORE_EFFECT,
    CANCELED_AFTER_PARTIAL_EFFECT,
    COMPLETED_BEFORE_CANCELLATION,
    FAILED_BEFORE_CANCELLATION,
    UNCERTAIN_WITHOUT_CANCELLATION,
    UNCERTAIN_AFTER_CANCELLATION
  }

  public IoCompletion {
    if (operationId < 1) {
      throw new IllegalArgumentException("operation identity must be positive");
    }
    Objects.requireNonNull(requestIdentity, "requestIdentity");
    Objects.requireNonNull(terminalKind, "terminalKind");
    Objects.requireNonNull(cancellationRelation, "cancellationRelation");
    Objects.requireNonNull(backend, "backend");
    if (progress < 0 || progress > declaredWork) {
      throw new IllegalArgumentException("completion progress exceeds declared work");
    }
    if (!resourcesReleased) {
      throw new IllegalArgumentException("terminal completion must release request resources");
    }
    boolean relationValid = switch (terminalKind) {
      case SUCCESS -> cancellationRelation == CancellationRelation.NOT_REQUESTED
          || cancellationRelation == CancellationRelation.COMPLETED_BEFORE_CANCELLATION;
      case FAILURE -> cancellationRelation == CancellationRelation.NOT_REQUESTED
          || cancellationRelation == CancellationRelation.FAILED_BEFORE_CANCELLATION;
      case CANCELED -> cancellationRelation == CancellationRelation.CANCELED_BEFORE_EFFECT
          || cancellationRelation == CancellationRelation.CANCELED_AFTER_PARTIAL_EFFECT;
      case UNCERTAIN -> cancellationRelation == CancellationRelation.UNCERTAIN_WITHOUT_CANCELLATION
          || cancellationRelation == CancellationRelation.UNCERTAIN_AFTER_CANCELLATION;
    };
    if (!relationValid) {
      throw new IllegalArgumentException("terminal kind and cancellation relation disagree");
    }
    if (cancellationRelation == CancellationRelation.CANCELED_BEFORE_EFFECT && progress != 0) {
      throw new IllegalArgumentException("cancellation before effect cannot report progress");
    }
    if (cancellationRelation == CancellationRelation.CANCELED_AFTER_PARTIAL_EFFECT
        && progress == 0) {
      throw new IllegalArgumentException("partial cancellation needs positive progress");
    }
    if (terminalKind == TerminalKind.SUCCESS) {
      Objects.requireNonNull(value, "successful value");
      if (detail != null) {
        throw new IllegalArgumentException("successful completion cannot carry detail");
      }
    } else {
      if (value != null) {
        throw new IllegalArgumentException("non-success completion cannot carry a value");
      }
      if (detail == null || detail.isBlank() || detail.length() > 256) {
        throw new IllegalArgumentException("non-success completion needs bounded detail");
      }
    }
  }

  /** Returns the successful value when this completion succeeded. */
  public Optional<T> successfulValue() {
    return Optional.ofNullable(value);
  }

  IoCompletion<T> withCancellationRelation(CancellationRelation relation) {
    return new IoCompletion<>(
        operationId,
        requestIdentity,
        terminalKind,
        relation,
        value,
        detail,
        progress,
        declaredWork,
        resourcesReleased,
        backend);
  }
}
