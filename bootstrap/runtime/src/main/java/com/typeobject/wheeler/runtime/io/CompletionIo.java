package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Bounded submission and completion queues driven by the awaiting scope thread. */
public final class CompletionIo {
  private final int queueCount;
  private final int queueDepth;
  private long nextScopeId = 1;

  /** Creates a backend with fixed queue topology and no per-operation worker. */
  public CompletionIo(int queueCount, int queueDepth) {
    if (queueCount < 1 || queueCount > 64) {
      throw new IllegalArgumentException("queue count must be between 1 and 64");
    }
    if (queueDepth < 1 || queueDepth > 4_096) {
      throw new IllegalArgumentException("queue depth must be between 1 and 4096");
    }
    this.queueCount = queueCount;
    this.queueDepth = queueDepth;
  }

  /** Opens one scope whose operation ceiling fits the physical queue capacity. */
  public synchronized IoScope scope(IoLimits limits) {
    Objects.requireNonNull(limits, "limits");
    int capacity = Math.multiplyExact(queueCount, queueDepth);
    if (limits.maxOperations() > capacity) {
      throw new IllegalArgumentException("scope operation limit exceeds queue capacity");
    }
    if (nextScopeId == Long.MAX_VALUE) {
      throw new IllegalStateException("completion scope identity exhausted");
    }
    return new IoScope(
        nextScopeId++,
        IoScope.Mode.COMPLETION,
        "bounded-completion-io-1",
        limits,
        null,
        queueCount,
        queueDepth);
  }
}
