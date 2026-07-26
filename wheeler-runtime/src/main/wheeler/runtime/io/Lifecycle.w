//! Enforces the bounded portable I/O operation lifecycle in caller-owned tables.

module wheeler.runtime.io.lifecycle;

classical class IoLifecycle {
  /// Names an unused operation row.
  public const long IO_STATE_EMPTY = 0;
  /// Names a submitted operation that has no terminal completion.
  public const long IO_STATE_SUBMITTED = 1;
  /// Names a terminal operation whose completion has not been reaped.
  public const long IO_STATE_TERMINAL = 2;
  /// Names an operation whose sole terminal completion was reaped.
  public const long IO_STATE_REAPED = 3;

  /// Names successful terminal completion.
  public const long IO_TERMINAL_SUCCESS = 1;
  /// Names known terminal failure.
  public const long IO_TERMINAL_FAILURE = 2;
  /// Names terminal cancellation.
  public const long IO_TERMINAL_CANCELED = 3;
  /// Names an uncertain terminal external outcome.
  public const long IO_TERMINAL_UNCERTAIN = 4;

  /// Names a completion for which cancellation was not requested.
  public const long IO_CANCEL_NOT_REQUESTED = 0;
  /// Names cancellation that won before any effect.
  public const long IO_CANCEL_BEFORE_EFFECT = 1;
  /// Names cancellation after known positive progress.
  public const long IO_CANCEL_AFTER_PARTIAL = 2;
  /// Names successful completion observed before cancellation.
  public const long IO_CANCEL_COMPLETION_WON = 3;
  /// Names known failure observed before cancellation.
  public const long IO_CANCEL_FAILURE_WON = 4;
  /// Names uncertainty not caused by cancellation.
  public const long IO_CANCEL_UNCERTAIN_WITHOUT_REQUEST = 5;
  /// Names uncertainty after cancellation raced with the effect.
  public const long IO_CANCEL_UNCERTAIN_AFTER_REQUEST = 6;

  /// Defines immutable `Submission` results for this module.
  public record Submission(long operation, long operationCount, long chargedWork, boolean valid) {}

  private boolean rowAvailable(
    borrow mut words states,
    borrow mut words work,
    borrow mut words progress,
    borrow mut words terminalKinds,
    borrow mut words cancellationRelations,
    borrow mut words resourcesReleased,
    borrow mut words reaped,
    long row
  ) {
    if (row < 0) {
      return false;
    }

    if (row < bufferLength(states)) {
      if (row < bufferLength(work)) {
        if (row < bufferLength(progress)) {
          if (row < bufferLength(terminalKinds)) {
            if (row < bufferLength(cancellationRelations)) {
              if (row < bufferLength(resourcesReleased)) {
                return row < bufferLength(reaped);
              }
            }
          }
        }
      }
    }

    return false;
  }

  private boolean completionRelationValid(
    long terminalKind,
    long cancellationRelation,
    long completedProgress
  ) {
    if (terminalKind == IO_TERMINAL_SUCCESS) {
      if (cancellationRelation == IO_CANCEL_NOT_REQUESTED) {
        return true;
      }

      return cancellationRelation == IO_CANCEL_COMPLETION_WON;
    }

    if (terminalKind == IO_TERMINAL_FAILURE) {
      if (cancellationRelation == IO_CANCEL_NOT_REQUESTED) {
        return true;
      }

      return cancellationRelation == IO_CANCEL_FAILURE_WON;
    }

    if (terminalKind == IO_TERMINAL_CANCELED) {
      if (cancellationRelation == IO_CANCEL_BEFORE_EFFECT) {
        return completedProgress == 0;
      }

      if (cancellationRelation == IO_CANCEL_AFTER_PARTIAL) {
        return 0 < completedProgress;
      }

      return false;
    }

    if (terminalKind == IO_TERMINAL_UNCERTAIN) {
      if (cancellationRelation == IO_CANCEL_UNCERTAIN_WITHOUT_REQUEST) {
        return true;
      }

      return cancellationRelation == IO_CANCEL_UNCERTAIN_AFTER_REQUEST;
    }

    return false;
  }

  /// Submits one bounded unit of work without publishing a partial row.
  public Submission submit(
    borrow mut words states,
    borrow mut words work,
    borrow mut words progress,
    borrow mut words terminalKinds,
    borrow mut words cancellationRelations,
    borrow mut words resourcesReleased,
    borrow mut words reaped,
    long operationCount,
    long chargedWork,
    long requestWork,
    long maxOperations,
    long maxWork
  ) {
    Submission invalid = new Submission(-1, operationCount, chargedWork, false);
    if (operationCount < 0) {
      return invalid;
    }

    if (maxOperations < 1) {
      return invalid;
    }

    if (64 < maxOperations) {
      return invalid;
    }

    if (operationCount < maxOperations) {} else {
      return invalid;
    }

    if (requestWork < 1) {
      return invalid;
    }

    if (chargedWork < 0) {
      return invalid;
    }

    if (maxWork < chargedWork) {
      return invalid;
    }

    if (maxWork - chargedWork < requestWork) {
      return invalid;
    }

    if (
      rowAvailable(
        states,
        work,
        progress,
        terminalKinds,
        cancellationRelations,
        resourcesReleased,
        reaped,
        operationCount
      ) == false
    ) {
      return invalid;
    }

    if (states[operationCount] == IO_STATE_EMPTY) {} else {
      return invalid;
    }

    set(states, operationCount, IO_STATE_SUBMITTED);
    set(work, operationCount, requestWork);
    set(progress, operationCount, 0);
    set(terminalKinds, operationCount, 0);
    set(cancellationRelations, operationCount, IO_CANCEL_NOT_REQUESTED);
    set(resourcesReleased, operationCount, 0);
    set(reaped, operationCount, 0);
    return new Submission(operationCount, operationCount + 1, chargedWork + requestWork, true);
  }

  /// Publishes one terminal completion after exact progress and resource release.
  public boolean complete(
    borrow mut words states,
    borrow mut words work,
    borrow mut words progress,
    borrow mut words terminalKinds,
    borrow mut words cancellationRelations,
    borrow mut words resourcesReleased,
    borrow mut words reaped,
    long operation,
    long terminalKind,
    long cancellationRelation,
    long completedProgress,
    boolean released
  ) {
    if (
      rowAvailable(
        states,
        work,
        progress,
        terminalKinds,
        cancellationRelations,
        resourcesReleased,
        reaped,
        operation
      ) == false
    ) {
      return false;
    }

    if (states[operation] == IO_STATE_SUBMITTED) {} else {
      return false;
    }

    if (released == false) {
      return false;
    }

    if (completedProgress < 0) {
      return false;
    }

    if (work[operation] < completedProgress) {
      return false;
    }

    if (
      completionRelationValid(terminalKind, cancellationRelation, completedProgress) == false
    ) {
      return false;
    }

    set(progress, operation, completedProgress);
    set(terminalKinds, operation, terminalKind);
    set(cancellationRelations, operation, cancellationRelation);
    set(resourcesReleased, operation, 1);
    set(states, operation, IO_STATE_TERMINAL);
    return true;
  }

  /// Completes cancellation before effect and releases captured resources.
  public boolean cancelBeforeEffect(
    borrow mut words states,
    borrow mut words work,
    borrow mut words progress,
    borrow mut words terminalKinds,
    borrow mut words cancellationRelations,
    borrow mut words resourcesReleased,
    borrow mut words reaped,
    long operation
  ) {
    return complete(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      operation,
      IO_TERMINAL_CANCELED,
      IO_CANCEL_BEFORE_EFFECT,
      0,
      true
    );
  }

  /// Records a cancellation request that lost to an existing terminal result.
  public boolean observeLateCancellation(
    borrow mut words states,
    borrow mut words terminalKinds,
    borrow mut words cancellationRelations,
    long operation
  ) {
    if (operation < 0) {
      return false;
    }

    if (operation < bufferLength(states)) {} else {
      return false;
    }

    if (operation < bufferLength(terminalKinds)) {} else {
      return false;
    }

    if (operation < bufferLength(cancellationRelations)) {} else {
      return false;
    }

    if (states[operation] == IO_STATE_TERMINAL) {} else {
      return false;
    }

    long terminalKind = terminalKinds[operation];
    long relation = cancellationRelations[operation];
    if (terminalKind == IO_TERMINAL_SUCCESS) {
      if (relation == IO_CANCEL_NOT_REQUESTED) {
        set(cancellationRelations, operation, IO_CANCEL_COMPLETION_WON);
        return true;
      }

      return false;
    }

    if (terminalKind == IO_TERMINAL_FAILURE) {
      if (relation == IO_CANCEL_NOT_REQUESTED) {
        set(cancellationRelations, operation, IO_CANCEL_FAILURE_WON);
        return true;
      }

      return false;
    }

    if (terminalKind == IO_TERMINAL_UNCERTAIN) {
      if (relation == IO_CANCEL_UNCERTAIN_WITHOUT_REQUEST) {
        set(cancellationRelations, operation, IO_CANCEL_UNCERTAIN_AFTER_REQUEST);
        return true;
      }
    }

    return false;
  }

  /// Reaps one terminal completion exactly once.
  public boolean reap(
    borrow mut words states,
    borrow mut words resourcesReleased,
    borrow mut words reaped,
    long operation
  ) {
    if (operation < 0) {
      return false;
    }

    if (operation < bufferLength(states)) {} else {
      return false;
    }

    if (operation < bufferLength(resourcesReleased)) {} else {
      return false;
    }

    if (operation < bufferLength(reaped)) {} else {
      return false;
    }

    if (states[operation] == IO_STATE_TERMINAL) {} else {
      return false;
    }

    if (resourcesReleased[operation] == 1) {} else {
      return false;
    }

    if (reaped[operation] == 0) {} else {
      return false;
    }

    set(reaped, operation, 1);
    set(states, operation, IO_STATE_REAPED);
    return true;
  }

  /// Checks that every published operation was terminal and reaped exactly once.
  public boolean scopeCanClose(borrow mut words states, long operationCount) {
    if (operationCount < 0) {
      return false;
    }

    if (64 < operationCount) {
      return false;
    }

    if (bufferLength(states) < operationCount) {
      return false;
    }

    long operation = 0;
    while (operation < operationCount) limit 64 {
      if (states[operation] == IO_STATE_REAPED) {} else {
        return false;
      }

      operation += 1;
    }

    return true;
  }
}
