//! Gives Wheeler source nominal request, operation, completion, queue, and effect rows.

module wheeler.runtime.io.portable;

import wheeler.runtime.io.lifecycle;

classical class PortableIo {
  public record Request(long identity, long work) {}

  public record Scope(long maxOperations, long maxWork) {}

  public record Operation(long identity) {}

  public record CompletionQueue(long head, long tail, long capacity) {}

  public record EffectBoundary(
    long operation,
    long terminalKind,
    long progress,
    long declaredWork
  ) {}

  public variant Admission {
    case Rejected();
    case Accepted(Operation operation, long operationCount, long chargedWork);
  }

  public variant Completion {
    case Success(Operation operation, long progress, long declaredWork, boolean released);
    case Failure(Operation operation, long progress, long declaredWork, boolean released);
    case Canceled(
      Operation operation,
      long relation,
      long progress,
      long declaredWork,
      boolean released
    );
    case Uncertain(
      Operation operation,
      long relation,
      long progress,
      long declaredWork,
      boolean released
    );
  }

  public variant QueuePush {
    case Full(CompletionQueue queue);
    case Value(CompletionQueue queue);
  }

  public variant QueuePop {
    case Empty(CompletionQueue queue);
    case Value(Operation operation, CompletionQueue queue);
  }

  public variant EffectLowering {
    case Reversible();
    case Live(EffectBoundary boundary);
  }

  /// Admits one pure request through the sole portable lifecycle transition.
  public Admission admitRequest(
    Request request,
    Scope scope,
    borrow mut words states,
    borrow mut words work,
    borrow mut words progress,
    borrow mut words terminalKinds,
    borrow mut words cancellationRelations,
    borrow mut words resourcesReleased,
    borrow mut words reaped,
    long operationCount,
    long chargedWork
  ) {
    if (request.identity < 0) {
      return new Admission.Rejected();
    }

    Submission admitted = submit(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      operationCount,
      chargedWork,
      request.work,
      scope.maxOperations,
      scope.maxWork
    );
    if (admitted.valid == false) {
      return new Admission.Rejected();
    }

    return new Admission.Accepted(
      new Operation(admitted.operation),
      admitted.operationCount,
      admitted.chargedWork
    );
  }

  /// Publishes one terminal row and returns its closed source completion value.
  public Completion publishCompletion(
    Operation operation,
    long terminalKind,
    long cancellationRelation,
    long completedProgress,
    boolean released,
    borrow mut words states,
    borrow mut words work,
    borrow mut words progress,
    borrow mut words terminalKinds,
    borrow mut words cancellationRelations,
    borrow mut words resourcesReleased,
    borrow mut words reaped
  ) {
    boolean published = complete(
      states,
      work,
      progress,
      terminalKinds,
      cancellationRelations,
      resourcesReleased,
      reaped,
      operation.identity,
      terminalKind,
      cancellationRelation,
      completedProgress,
      released
    );
    assert(published);
    long declaredWork = work[operation.identity];
    if (terminalKind == IO_TERMINAL_SUCCESS) {
      return new Completion.Success(operation, completedProgress, declaredWork, released);
    }

    if (terminalKind == IO_TERMINAL_FAILURE) {
      return new Completion.Failure(operation, completedProgress, declaredWork, released);
    }

    if (terminalKind == IO_TERMINAL_CANCELED) {
      return new Completion.Canceled(
        operation,
        cancellationRelation,
        completedProgress,
        declaredWork,
        released
      );
    }

    return new Completion.Uncertain(
      operation,
      cancellationRelation,
      completedProgress,
      declaredWork,
      released
    );
  }

  /// Reaps one terminal operation through the sole source-level permission.
  public boolean reapOperation(
    Operation operation,
    borrow mut words states,
    borrow mut words resourcesReleased,
    borrow mut words reaped
  ) {
    return reap(states, resourcesReleased, reaped, operation.identity);
  }

  /// Enqueues one operation identity without running provider work.
  public QueuePush pushOperation(
    borrow mut words values,
    CompletionQueue queue,
    Operation operation
  ) {
    if (queue.capacity < 1) {
      return new QueuePush.Full(queue);
    }

    if (bufferLength(values) < queue.capacity) {
      return new QueuePush.Full(queue);
    }

    if (queue.tail - queue.head < queue.capacity) {
      set(values, queue.tail % queue.capacity, operation.identity);
      return new QueuePush.Value(
        new CompletionQueue(queue.head, queue.tail + 1, queue.capacity)
      );
    }

    return new QueuePush.Full(queue);
  }

  /// Dequeues one operation identity in canonical FIFO order.
  public QueuePop popOperation(borrow mut words values, CompletionQueue queue) {
    if (queue.head < queue.tail) {
      long operation = values[queue.head % queue.capacity];
      return new QueuePop.Value(
        new Operation(operation),
        new CompletionQueue(queue.head + 1, queue.tail, queue.capacity)
      );
    }

    return new QueuePop.Empty(queue);
  }

  /// Lowers external completion to a live effect boundary, never an inverse.
  public EffectLowering lowerEffect(Completion completion) {
    match (completion) {
      case Completion.Success(
        Operation successOperation,
        long successProgress,
        long successWork,
        boolean successReleased
      ) {
        assert(successReleased);
        return new EffectLowering.Live(
          new EffectBoundary(
            successOperation.identity,
            IO_TERMINAL_SUCCESS,
            successProgress,
            successWork
          )
        );
      }
      case Completion.Failure(
        Operation failureOperation,
        long failureProgress,
        long failureWork,
        boolean failureReleased
      ) {
        assert(failureReleased);
        return new EffectLowering.Live(
          new EffectBoundary(
            failureOperation.identity,
            IO_TERMINAL_FAILURE,
            failureProgress,
            failureWork
          )
        );
      }
      case Completion.Canceled(
        Operation canceledOperation,
        long canceledRelation,
        long canceledProgress,
        long canceledWork,
        boolean canceledReleased
      ) {
        assert(canceledReleased);
        assert(-1 < canceledRelation);
        return new EffectLowering.Live(
          new EffectBoundary(
            canceledOperation.identity,
            IO_TERMINAL_CANCELED,
            canceledProgress,
            canceledWork
          )
        );
      }
      case Completion.Uncertain(
        Operation uncertainOperation,
        long uncertainRelation,
        long uncertainProgress,
        long uncertainWork,
        boolean uncertainReleased
      ) {
        assert(uncertainReleased);
        assert(-1 < uncertainRelation);
        return new EffectLowering.Live(
          new EffectBoundary(
            uncertainOperation.identity,
            IO_TERMINAL_UNCERTAIN,
            uncertainProgress,
            uncertainWork
          )
        );
      }
    }
  }
}
