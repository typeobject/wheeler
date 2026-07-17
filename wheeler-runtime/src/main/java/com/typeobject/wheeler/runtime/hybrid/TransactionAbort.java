package com.typeobject.wheeler.runtime.hybrid;

/** Honest result of aborting a hybrid transaction. */
public record TransactionAbort(
    TransactionPhase previousPhase,
    boolean cancellationRequested,
    boolean observationDiscarded,
    String activeBranch) {}
