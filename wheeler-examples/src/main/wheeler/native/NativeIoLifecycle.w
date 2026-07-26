//! Exercises terminal completion, cancellation, uncertainty, and exact reaping.

module examples.native.io_lifecycle;

import wheeler.runtime.io.lifecycle;

classical class NativeIoLifecycle {
  state long finalOperationCount = 0;
  state long finalChargedWork = 0;
  state long completionWonRelation = 0;
  state long uncertainRelation = 0;
  state long rejectedOperation = 0;
  state long finalClosed = 0;

  /// Runs the bounded Wheeler-native I/O lifecycle state machine.
  ///
  /// - Effects: Mutates declared lifecycle columns and fixture state.
  entry void main() {
    region arena = new region(2048, 8);
    words states = allocate(arena, 4);
    words work = allocate(arena, 4);
    words progress = allocate(arena, 4);
    words terminalKinds = allocate(arena, 4);
    words cancellationRelations = allocate(arena, 4);
    words resourcesReleased = allocate(arena, 4);
    words reaped = allocate(arena, 4);

    Submission first = submit(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      0,
      0,
      8,
      4,
      32
    );
    assert(first.valid);
    assert(scopeCanClose(states, first.operationCount) == false);
    assert(
      complete(
        states,
        work,
        progress,
        terminalKinds,
        cancellationRelations,
        resourcesReleased,
        reaped,
        first.operation,
        IO_TERMINAL_SUCCESS,
        IO_CANCEL_NOT_REQUESTED,
        8,
        true
      )
    );
    assert(
      complete(
        states,
        work,
        progress,
        terminalKinds,
        cancellationRelations,
        resourcesReleased,
        reaped,
        first.operation,
        IO_TERMINAL_SUCCESS,
        IO_CANCEL_NOT_REQUESTED,
        8,
        true
      ) == false
    );
    assert(
      observeLateCancellation(states, terminalKinds, cancellationRelations, first.operation)
    );
    completionWonRelation = cancellationRelations[first.operation];
    assert(reap(states, resourcesReleased, reaped, first.operation));
    assert(reap(states, resourcesReleased, reaped, first.operation) == false);

    Submission second = submit(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      first.operationCount,
      first.chargedWork,
      4,
      4,
      32
    );
    assert(second.valid);
    assert(
      cancelBeforeEffect(
        states,
        work,
        progress,
        terminalKinds,
        cancellationRelations,
        resourcesReleased,
        reaped,
        second.operation
      )
    );
    assert(progress[second.operation] == 0);
    assert(resourcesReleased[second.operation] == 1);
    assert(reap(states, resourcesReleased, reaped, second.operation));

    Submission third = submit(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      second.operationCount,
      second.chargedWork,
      5,
      4,
      32
    );
    assert(third.valid);
    assert(
      complete(
        states,
        work,
        progress,
        terminalKinds,
        cancellationRelations,
        resourcesReleased,
        reaped,
        third.operation,
        IO_TERMINAL_CANCELED,
        IO_CANCEL_AFTER_PARTIAL,
        3,
        true
      )
    );
    assert(reap(states, resourcesReleased, reaped, third.operation));

    Submission fourth = submit(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      third.operationCount,
      third.chargedWork,
      6,
      4,
      32
    );
    assert(fourth.valid);
    assert(
      complete(
        states,
        work,
        progress,
        terminalKinds,
        cancellationRelations,
        resourcesReleased,
        reaped,
        fourth.operation,
        IO_TERMINAL_UNCERTAIN,
        IO_CANCEL_UNCERTAIN_WITHOUT_REQUEST,
        2,
        true
      )
    );
    assert(
      observeLateCancellation(states, terminalKinds, cancellationRelations, fourth.operation)
    );
    uncertainRelation = cancellationRelations[fourth.operation];
    assert(reap(states, resourcesReleased, reaped, fourth.operation));

    Submission rejected = submit(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      fourth.operationCount,
      fourth.chargedWork,
      1,
      4,
      32
    );
    if (rejected.valid) {
      rejectedOperation = 1;
    }

    finalOperationCount = fourth.operationCount;
    finalChargedWork = fourth.chargedWork;
    if (scopeCanClose(states, fourth.operationCount)) {
      finalClosed = 1;
    }

    drop(reaped);
    drop(resourcesReleased);
    drop(cancellationRelations);
    drop(terminalKinds);
    drop(progress);
    drop(work);
    drop(states);
    drop(arena);
  }
}
