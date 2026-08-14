package com.typeobject.wheeler.runtime.io;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousFileChannel;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/** Bounded asynchronous host-file capability beneath completion-queue delivery. */
public final class NativeCompletionFile implements AutoCloseable {
  /** Rights fixed at capability construction. */
  public enum Rights {
    READ_ONLY,
    READ_WRITE
  }

  /** Successful asynchronous read with exact owner and progress. */
  public record ReadCompleted(OwnedIoBuffer buffer, long position, int bytesRead) {}

  /** Successful asynchronous write with exact owner and progress. */
  public record WriteCompleted(OwnedIoBuffer buffer, long position, int bytesWritten) {}

  private static final long MAX_FILE_BYTES = 16L * 1024 * 1024;

  private final String identity;
  private final Rights rights;
  private final long maximumBytes;
  private final int maximumInFlight;
  private final ThreadPoolExecutor executor;
  private final AsynchronousFileChannel channel;
  private final AtomicInteger activeRequests = new AtomicInteger();
  private boolean closed;

  private NativeCompletionFile(
      String identity,
      Rights rights,
      long maximumBytes,
      int maximumInFlight,
      ThreadPoolExecutor executor,
      AsynchronousFileChannel channel) {
    this.identity = identity;
    this.rights = rights;
    this.maximumBytes = maximumBytes;
    this.maximumInFlight = maximumInFlight;
    this.executor = executor;
    this.channel = channel;
  }

  /** Opens one no-follow asynchronous file over a fixed bounded executor. */
  public static NativeCompletionFile open(
      String identity,
      Path path,
      Rights rights,
      long maximumBytes,
      int workers,
      int maximumInFlight) throws IOException {
    DurabilitySubject.visibleAscii("identity", identity, 160, false);
    Objects.requireNonNull(path, "path");
    Objects.requireNonNull(rights, "rights");
    if (maximumBytes < 1 || MAX_FILE_BYTES < maximumBytes) {
      throw new IllegalArgumentException("completion file extent must be 1 byte through 16 MiB");
    }
    if (workers < 1 || 64 < workers || maximumInFlight < workers
        || 4_096 < maximumInFlight) {
      throw new IllegalArgumentException("completion executor bounds are invalid");
    }
    Path normalized = path.toAbsolutePath().normalize();
    if (Files.isSymbolicLink(normalized)) {
      throw new IOException("completion file capability rejects symbolic links");
    }
    ThreadPoolExecutor executor = new ThreadPoolExecutor(
        workers,
        workers,
        0,
        TimeUnit.MILLISECONDS,
        new ArrayBlockingQueue<>(maximumInFlight),
        new ThreadPoolExecutor.AbortPolicy());
    Set<OpenOption> options = new HashSet<>();
    options.add(StandardOpenOption.READ);
    options.add(LinkOption.NOFOLLOW_LINKS);
    if (rights == Rights.READ_WRITE) {
      options.add(StandardOpenOption.CREATE);
      options.add(StandardOpenOption.WRITE);
    }
    try {
      AsynchronousFileChannel channel = AsynchronousFileChannel.open(
          normalized, options, executor);
      if (channel.size() > maximumBytes) {
        channel.close();
        throw new IOException("completion file exceeds its capability extent");
      }
      return new NativeCompletionFile(
          identity, rights, maximumBytes, maximumInFlight, executor, channel);
    } catch (Throwable failure) {
      executor.shutdownNow();
      throw failure;
    }
  }

  /** Prepares one asynchronous positional read without submitting provider work. */
  public synchronized IoRequest<ReadCompleted> readAt(
      long position, OwnedIoBuffer destination, int bufferOffset, int length) {
    requireOpen();
    Objects.requireNonNull(destination, "destination");
    checkRange(position, destination, bufferOffset, length);
    reserve(destination);
    AtomicReference<java.util.concurrent.Future<Integer>> future = new AtomicReference<>();
    try {
      return IoRequest.prepare(
          identity + ":completion-read:" + position + ":" + bufferOffset + ":" + length,
          Math.max(1, length),
          () -> executeRead(position, destination, bufferOffset, length, future),
          () -> release(destination),
          () -> cancel(future));
    } catch (RuntimeException failure) {
      release(destination);
      throw failure;
    }
  }

  /** Prepares one asynchronous positional write without submitting provider work. */
  public synchronized IoRequest<WriteCompleted> writeAt(
      long position, OwnedIoBuffer source, int bufferOffset, int length) {
    requireOpen();
    if (rights != Rights.READ_WRITE) {
      throw new IllegalStateException("completion file capability is read-only");
    }
    Objects.requireNonNull(source, "source");
    checkRange(position, source, bufferOffset, length);
    reserve(source);
    AtomicReference<java.util.concurrent.Future<Integer>> future = new AtomicReference<>();
    try {
      return IoRequest.prepare(
          identity + ":completion-write:" + position + ":" + bufferOffset + ":" + length,
          Math.max(1, length),
          () -> executeWrite(position, source, bufferOffset, length, future),
          () -> release(source),
          () -> cancel(future));
    } catch (RuntimeException failure) {
      release(source);
      throw failure;
    }
  }

  public int workers() {
    return executor.getCorePoolSize();
  }

  public int maximumInFlight() {
    return maximumInFlight;
  }

  @Override
  public synchronized void close() throws IOException {
    if (closed) {
      return;
    }
    if (activeRequests.get() != 0) {
      throw new IllegalStateException("completion file has unreaped request resources");
    }
    closed = true;
    channel.close();
    executor.shutdown();
  }

  private IoProviderResult<ReadCompleted> executeRead(
      long position,
      OwnedIoBuffer destination,
      int bufferOffset,
      int length,
      AtomicReference<java.util.concurrent.Future<Integer>> reference) {
    ByteBuffer target = ByteBuffer.allocate(length);
    try {
      java.util.concurrent.Future<Integer> operation = channel.read(target, position);
      reference.set(operation);
      int read = Math.max(0, operation.get());
      destination.copyFrom(target.array(), 0, bufferOffset, read);
      return IoProviderResult.success(new ReadCompleted(destination, position, read), read);
    } catch (CancellationException failure) {
      return IoProviderResult.uncertain("native-completion-read-canceled", 0);
    } catch (InterruptedException failure) {
      Thread.currentThread().interrupt();
      return IoProviderResult.uncertain("native-completion-read-interrupted", 0);
    } catch (ExecutionException | RuntimeException failure) {
      return IoProviderResult.failure("native-completion-read-failed", 0);
    }
  }

  private IoProviderResult<WriteCompleted> executeWrite(
      long position,
      OwnedIoBuffer source,
      int bufferOffset,
      int length,
      AtomicReference<java.util.concurrent.Future<Integer>> reference) {
    byte[] bytes = new byte[length];
    source.copyTo(bufferOffset, bytes, 0, length);
    try {
      java.util.concurrent.Future<Integer> operation = channel.write(ByteBuffer.wrap(bytes), position);
      reference.set(operation);
      int written = operation.get();
      return IoProviderResult.success(new WriteCompleted(source, position, written), written);
    } catch (CancellationException failure) {
      return IoProviderResult.uncertain("native-completion-write-canceled", 0);
    } catch (InterruptedException failure) {
      Thread.currentThread().interrupt();
      return IoProviderResult.uncertain("native-completion-write-interrupted", 0);
    } catch (ExecutionException | RuntimeException failure) {
      return IoProviderResult.failure("native-completion-write-failed", 0);
    }
  }

  private synchronized void reserve(OwnedIoBuffer buffer) {
    if (maximumInFlight <= activeRequests.get()) {
      throw new IllegalStateException("completion file in-flight capacity exhausted");
    }
    buffer.hold();
    activeRequests.incrementAndGet();
  }

  private synchronized void release(OwnedIoBuffer buffer) {
    buffer.release();
    if (activeRequests.decrementAndGet() < 0) {
      throw new IllegalStateException("completion file request accounting underflow");
    }
  }

  private static void cancel(AtomicReference<java.util.concurrent.Future<Integer>> reference) {
    java.util.concurrent.Future<Integer> operation = reference.get();
    if (operation != null) {
      operation.cancel(false);
    }
  }

  private void checkRange(
      long position, OwnedIoBuffer buffer, int bufferOffset, int length) {
    int capacity = buffer.length();
    if (position < 0 || length < 0 || maximumBytes < position
        || maximumBytes - position < length || bufferOffset < 0
        || capacity < bufferOffset || capacity - bufferOffset < length) {
      throw new IllegalArgumentException("completion file range is outside its capability");
    }
  }

  private void requireOpen() {
    if (closed) {
      throw new IllegalStateException("completion file capability is closed");
    }
  }
}
