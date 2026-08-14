package com.typeobject.wheeler.runtime.io;

/** Fixed-worker stage-0 adapter for interrupt-style terminal completion delivery. */
public final class InterruptIo implements AutoCloseable {
  private final ThreadedIo.Dispatcher dispatcher;
  private long nextScopeId = 1;
  private boolean closed;

  /** Creates one bounded interrupt-delivery profile over the common dispatcher. */
  public InterruptIo(int workers, int maxInFlight) {
    ThreadedIo.validateLimits(workers, maxInFlight);
    dispatcher = new ThreadedIo.Dispatcher(workers, maxInFlight);
  }

  /** Opens one scope with interrupt-style terminal notification. */
  public synchronized IoScope scope(IoLimits limits) {
    if (closed) {
      throw new IllegalStateException("interrupt I/O backend is closed");
    }
    if (nextScopeId == Long.MAX_VALUE) {
      throw new IllegalStateException("interrupt scope identity exhausted");
    }
    return new IoScope(
        nextScopeId++,
        IoScope.Mode.THREADED,
        "bounded-interrupt-io-1",
        limits,
        dispatcher);
  }

  /** Closes only after every admitted operation has reached a terminal result. */
  @Override
  public synchronized void close() {
    dispatcher.close();
    closed = true;
  }
}
