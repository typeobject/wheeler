package com.typeobject.wheeler.runtime.io;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/** Bounded registered-buffer pool with generation-checked provider loans and explicit reuse. */
public final class IoBufferPool implements AutoCloseable {
  private static final int MAX_BUFFERS = 4_096;
  private static final long MAX_BYTES = 16L * 1024 * 1024;

  /** One affine caller lease over a registered buffer generation. */
  public static final class Lease {
    private final IoBufferPool owner;
    private final int index;
    private final long generation;

    private Lease(IoBufferPool owner, int index, long generation) {
      this.owner = owner;
      this.index = index;
      this.generation = generation;
    }

    public int length() {
      return owner.buffer(this).length();
    }

    public byte get(int offset) {
      return owner.buffer(this).get(offset);
    }

    public void put(int offset, byte value) {
      owner.buffer(this).put(offset, value);
    }

    public byte[] snapshot() {
      return owner.buffer(this).snapshot();
    }
  }

  /** Terminal provided-buffer read result without exposing the registered owner. */
  public record ReadCompleted(
      Lease lease, long position, int bufferOffset, int bytesRead) {}

  /** Terminal registered-buffer write result without exposing the registered owner. */
  public record WriteCompleted(
      Lease lease, long position, int bufferOffset, int bytesWritten) {}

  private final List<OwnedIoBuffer> buffers;
  private final long[] generations;
  private final boolean[] leased;
  private boolean closed;

  public IoBufferPool(int bufferCount, int bufferBytes) {
    if (bufferCount < 1 || bufferCount > MAX_BUFFERS
        || bufferBytes < 1
        || Math.multiplyExact((long) bufferCount, bufferBytes) > MAX_BYTES) {
      throw new IllegalArgumentException("I/O buffer pool exceeds its count or byte limit");
    }
    List<OwnedIoBuffer> allocated = new ArrayList<>(bufferCount);
    for (int index = 0; index < bufferCount; index++) {
      OwnedIoBuffer buffer = OwnedIoBuffer.allocate(bufferBytes);
      buffer.hold();
      allocated.add(buffer);
    }
    buffers = List.copyOf(allocated);
    generations = new long[bufferCount];
    leased = new boolean[bufferCount];
  }

  /** Acquires the lowest available registered buffer, if one remains. */
  public synchronized Optional<Lease> acquire() {
    requireOpen();
    for (int index = 0; index < buffers.size(); index++) {
      if (!leased[index]) {
        leased[index] = true;
        buffers.get(index).release();
        return Optional.of(new Lease(this, index, generations[index]));
      }
    }
    return Optional.empty();
  }

  /** Returns one terminal lease to the provider pool and invalidates its generation. */
  public synchronized void recycle(Lease lease) {
    OwnedIoBuffer buffer = buffer(lease);
    buffer.length();
    if (generations[lease.index] == Long.MAX_VALUE) {
      throw new IllegalStateException("I/O buffer generation exhausted");
    }
    buffer.hold();
    leased[lease.index] = false;
    generations[lease.index]++;
  }

  /** Prepares one provided-buffer positional read without running provider work. */
  public IoRequest<ReadCompleted> readAt(
      MemoryAddressableFile file,
      long position,
      Lease lease,
      int bufferOffset,
      int length) {
    OwnedIoBuffer buffer = buffer(lease);
    IoRequest<MemoryAddressableFile.ReadCompleted> positional =
        file.readAt(position, buffer, bufferOffset, length);
    try {
      return IoRequest.prepare(
          positional.identity() + ":pool:" + lease.index + ":" + lease.generation,
          positional.work(),
          () -> mapRead(positional, lease),
          positional::releaseResources);
    } catch (RuntimeException failure) {
      positional.releaseResources();
      throw failure;
    }
  }

  /** Prepares one registered-buffer positional write without a staging-buffer copy. */
  public IoRequest<WriteCompleted> writeAt(
      MemoryAddressableFile file,
      long position,
      Lease lease,
      int bufferOffset,
      int length) {
    OwnedIoBuffer buffer = buffer(lease);
    IoRequest<MemoryAddressableFile.WriteCompleted> positional =
        file.writeAt(position, buffer, bufferOffset, length);
    try {
      return IoRequest.prepare(
          positional.identity() + ":pool:" + lease.index + ":" + lease.generation,
          positional.work(),
          () -> mapWrite(positional, lease),
          positional::releaseResources);
    } catch (RuntimeException failure) {
      positional.releaseResources();
      throw failure;
    }
  }

  public synchronized int availableCount() {
    requireOpen();
    int available = 0;
    for (boolean active : leased) {
      if (!active) {
        available++;
      }
    }
    return available;
  }

  @Override
  public synchronized void close() {
    if (closed) {
      return;
    }
    for (boolean active : leased) {
      if (active) {
        throw new IllegalStateException("I/O buffer pool closes with a live lease");
      }
    }
    closed = true;
  }

  private synchronized OwnedIoBuffer buffer(Lease lease) {
    requireOpen();
    if (lease == null
        || lease.owner != this
        || lease.index < 0
        || lease.index >= buffers.size()
        || !leased[lease.index]
        || generations[lease.index] != lease.generation) {
      throw new IllegalStateException("I/O buffer lease is stale or foreign");
    }
    return buffers.get(lease.index);
  }

  private void requireOpen() {
    if (closed) {
      throw new IllegalStateException("I/O buffer pool is closed");
    }
  }

  private static IoProviderResult<ReadCompleted> mapRead(
      IoRequest<MemoryAddressableFile.ReadCompleted> positional, Lease lease) {
    IoProviderResult<MemoryAddressableFile.ReadCompleted> result = positional.execute();
    if (result.kind() != IoProviderResult.Kind.SUCCESS) {
      return failed(result);
    }
    MemoryAddressableFile.ReadCompleted value = result.value();
    return IoProviderResult.success(
        new ReadCompleted(lease, value.position(), value.bufferOffset(), value.bytesRead()),
        result.progress());
  }

  private static IoProviderResult<WriteCompleted> mapWrite(
      IoRequest<MemoryAddressableFile.WriteCompleted> positional, Lease lease) {
    IoProviderResult<MemoryAddressableFile.WriteCompleted> result = positional.execute();
    if (result.kind() != IoProviderResult.Kind.SUCCESS) {
      return failed(result);
    }
    MemoryAddressableFile.WriteCompleted value = result.value();
    return IoProviderResult.success(
        new WriteCompleted(lease, value.position(), value.bufferOffset(), value.bytesWritten()),
        result.progress());
  }

  private static <T> IoProviderResult<T> failed(IoProviderResult<?> result) {
    return switch (result.kind()) {
      case FAILURE -> IoProviderResult.failure(result.detail(), result.progress());
      case CANCELED_AFTER_PARTIAL_EFFECT ->
        IoProviderResult.canceledAfterPartial(result.detail(), result.progress());
      case UNCERTAIN -> IoProviderResult.uncertain(result.detail(), result.progress());
      case SUCCESS -> throw new IllegalArgumentException("successful result requires a value");
    };
  }
}
