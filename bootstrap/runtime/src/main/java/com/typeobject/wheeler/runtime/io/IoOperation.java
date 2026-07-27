package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Affine must-reap handle for one submitted request. */
public final class IoOperation<T> {
  private final IoScope owner;
  private final long id;
  private final IoRequest<T> request;
  private volatile IoCompletion<T> completion;
  private volatile boolean reaped;
  private boolean started;
  private boolean cancellationRequested;

  IoOperation(IoScope owner, long id, IoRequest<T> request) {
    this.owner = Objects.requireNonNull(owner, "owner");
    this.id = id;
    this.request = Objects.requireNonNull(request, "request");
  }

  /** Returns the scope-local deterministic operation identity. */
  public long id() {
    return id;
  }

  /** Returns the prepared request identity. */
  public String requestIdentity() {
    return request.identity();
  }

  /** Returns whether terminal completion has been recorded. */
  public boolean isTerminal() {
    return completion != null;
  }

  /** Returns whether the sole terminal completion has been consumed. */
  public boolean isReaped() {
    return reaped;
  }

  /** Requests cancellation without consuming this operation. */
  public boolean cancel() {
    return owner.cancel(this);
  }

  /** Waits for terminal completion and reaps it exactly once. */
  public IoCompletion<T> await() {
    return owner.await(this);
  }

  IoRequest<T> request() {
    return request;
  }

  IoCompletion<T> completion() {
    return completion;
  }

  boolean isStarted() {
    return started;
  }

  void markStarted() {
    if (started || completion != null) {
      throw new IllegalStateException("operation cannot start twice: " + id);
    }
    started = true;
  }

  boolean cancellationRequested() {
    return cancellationRequested;
  }

  void requestCancellation() {
    cancellationRequested = true;
  }

  void complete(IoCompletion<T> terminal) {
    if (completion != null) {
      throw new IllegalStateException("operation completed more than once: " + id);
    }
    completion = Objects.requireNonNull(terminal, "terminal");
  }

  void replaceCompletion(IoCompletion<T> terminal) {
    if (completion == null || reaped) {
      throw new IllegalStateException("operation completion cannot be replaced: " + id);
    }
    completion = Objects.requireNonNull(terminal, "terminal");
  }

  void markReaped() {
    if (completion == null) {
      throw new IllegalStateException("live operation cannot be reaped: " + id);
    }
    if (reaped) {
      throw new IllegalStateException("operation reaped more than once: " + id);
    }
    reaped = true;
  }

  boolean ownedBy(IoScope scope) {
    return owner == scope;
  }
}
