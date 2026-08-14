package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Canonical numeric lifecycle rows shared with the Wheeler-native transition table. */
public final class IoLifecycleEncoding {
  private IoLifecycleEncoding() {}

  /** Encodes success, known failure, cancellation, and uncertainty as rows 1 through 4. */
  public static int terminal(IoCompletion.TerminalKind kind) {
    Objects.requireNonNull(kind, "kind");
    return switch (kind) {
      case SUCCESS -> 1;
      case FAILURE -> 2;
      case CANCELED -> 3;
      case UNCERTAIN -> 4;
    };
  }

  /** Encodes the seven cancellation relations as rows 0 through 6. */
  public static int cancellation(IoCompletion.CancellationRelation relation) {
    Objects.requireNonNull(relation, "relation");
    return switch (relation) {
      case NOT_REQUESTED -> 0;
      case CANCELED_BEFORE_EFFECT -> 1;
      case CANCELED_AFTER_PARTIAL_EFFECT -> 2;
      case COMPLETED_BEFORE_CANCELLATION -> 3;
      case FAILED_BEFORE_CANCELLATION -> 4;
      case UNCERTAIN_WITHOUT_CANCELLATION -> 5;
      case UNCERTAIN_AFTER_CANCELLATION -> 6;
    };
  }

  /** Encodes one exact terminal row without backend-specific delivery facts. */
  public static long[] terminalRow(IoCompletion<?> completion) {
    Objects.requireNonNull(completion, "completion");
    return new long[] {
        terminal(completion.terminalKind()),
        cancellation(completion.cancellationRelation()),
        completion.progress(),
        completion.declaredWork(),
        completion.resourcesReleased() ? 1 : 0
    };
  }
}
