package com.typeobject.wheeler.runtime.io;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.Semaphore;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/** Portable bounded threaded backend for the common I/O lifecycle. */
public final class ThreadedIo implements AutoCloseable {
  static final class Dispatcher {
    private final int maxInFlight;
    private final Semaphore admission;
    private final ThreadPoolExecutor executor;
    private boolean closed;

    Dispatcher(int workers, int maxInFlight) {
      this.maxInFlight = maxInFlight;
      admission = new Semaphore(maxInFlight, true);
      BlockingQueue<Runnable> queue = new ArrayBlockingQueue<>(maxInFlight);
      AtomicInteger threadIds = new AtomicInteger();
      ThreadFactory threads = task -> {
        Thread thread = new Thread(task, "wheeler-io-" + threadIds.getAndIncrement());
        thread.setDaemon(true);
        return thread;
      };
      executor = new ThreadPoolExecutor(
          workers,
          workers,
          0,
          TimeUnit.MILLISECONDS,
          queue,
          threads,
          new ThreadPoolExecutor.AbortPolicy());
    }

    synchronized void reserve(int count) {
      requireOpen();
      if (!admission.tryAcquire(count)) {
        throw new IllegalStateException("threaded I/O admission capacity exceeded");
      }
    }

    synchronized void submit(Runnable task) {
      requireOpen();
      try {
        executor.execute(task);
      } catch (RejectedExecutionException impossible) {
        throw new IllegalStateException("reserved threaded I/O work was rejected", impossible);
      }
    }

    void release() {
      admission.release();
    }

    synchronized void requireOpen() {
      if (closed) {
        throw new IllegalStateException("threaded I/O backend is closed");
      }
    }

    synchronized void close() {
      if (admission.availablePermits() != maxInFlight) {
        throw new IllegalStateException("threaded I/O backend has admitted work");
      }
      closed = true;
      executor.shutdown();
      try {
        if (!executor.awaitTermination(5, TimeUnit.SECONDS)) {
          throw new IllegalStateException("threaded I/O workers did not terminate");
        }
      } catch (InterruptedException interrupted) {
        Thread.currentThread().interrupt();
        throw new IllegalStateException("interrupted while closing threaded I/O", interrupted);
      }
    }
  }

  private final Dispatcher dispatcher;
  private long nextScopeId = 1;
  private boolean closed;

  public ThreadedIo(int workers, int maxInFlight) {
    if (workers < 1 || workers > 64) {
      throw new IllegalArgumentException("thread worker count must be between 1 and 64");
    }
    if (maxInFlight < workers || maxInFlight > 10_000) {
      throw new IllegalArgumentException("maxInFlight must be between workers and 10000");
    }
    dispatcher = new Dispatcher(workers, maxInFlight);
  }

  /** Opens one bounded scope sharing this backend's admitted worker capacity. */
  public synchronized IoScope scope(IoLimits limits) {
    if (closed) {
      throw new IllegalStateException("threaded I/O backend is closed");
    }
    if (nextScopeId == Long.MAX_VALUE) {
      throw new IllegalStateException("threaded scope identity exhausted");
    }
    return new IoScope(
        nextScopeId++,
        IoScope.Mode.THREADED,
        "bounded-threaded-io-1",
        limits,
        dispatcher);
  }

  /** Closes the worker backend only after every admitted operation is terminal. */
  @Override
  public synchronized void close() {
    dispatcher.close();
    closed = true;
  }
}
