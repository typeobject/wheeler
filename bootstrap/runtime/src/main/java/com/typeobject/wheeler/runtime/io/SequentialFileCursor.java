package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Single-owner sequential adapter over one positional file capability. */
public final class SequentialFileCursor {
  /** Terminal sequential read with exact cursor coordinates. */
  public record ReadCompleted(
      OwnedIoBuffer buffer, long consumedPosition, long examinedPosition, int bytesRead) {}

  /** Terminal sequential write with the advanced cursor coordinate. */
  public record WriteCompleted(OwnedIoBuffer buffer, long position, int bytesWritten) {}

  private final MemoryAddressableFile file;
  private long consumed;
  private long examined;
  private boolean pending;

  public SequentialFileCursor(MemoryAddressableFile file) {
    this.file = Objects.requireNonNull(file, "file");
  }

  /** Returns the first byte not released by the consumer. */
  public synchronized long consumedPosition() {
    requireIdle();
    return consumed;
  }

  /** Returns the first byte not yet examined by a completed read. */
  public synchronized long examinedPosition() {
    requireIdle();
    return examined;
  }

  /** Moves the two read coordinates within the completed examined window. */
  public synchronized void advance(long nextConsumed, long nextExamined) {
    requireIdle();
    if (nextConsumed < consumed
        || nextConsumed > nextExamined
        || nextExamined > examined) {
      throw new IllegalArgumentException("sequential cursor advance is outside the examined window");
    }
    consumed = nextConsumed;
    examined = nextExamined;
  }

  /** Prepares one read at the current examined position and lends the cursor until completion. */
  public synchronized IoRequest<ReadCompleted> read(
      OwnedIoBuffer destination, int bufferOffset, int length) {
    requireIdle();
    long position = examined;
    IoRequest<MemoryAddressableFile.ReadCompleted> positional =
        file.readAt(position, destination, bufferOffset, length);
    pending = true;
    try {
      return IoRequest.prepare(
          positional.identity() + ":sequential",
          positional.work(),
          () -> completeRead(positional, position),
          () -> release(positional));
    } catch (RuntimeException failure) {
      pending = false;
      positional.releaseResources();
      throw failure;
    }
  }

  /** Prepares one write at the current examined position and lends the cursor until completion. */
  public synchronized IoRequest<WriteCompleted> write(
      OwnedIoBuffer source, int bufferOffset, int length) {
    requireIdle();
    if (consumed != examined) {
      throw new IllegalStateException("sequential write requires one settled cursor position");
    }
    long position = examined;
    IoRequest<MemoryAddressableFile.WriteCompleted> positional =
        file.writeAt(position, source, bufferOffset, length);
    pending = true;
    try {
      return IoRequest.prepare(
          positional.identity() + ":sequential",
          positional.work(),
          () -> completeWrite(positional, position),
          () -> release(positional));
    } catch (RuntimeException failure) {
      pending = false;
      positional.releaseResources();
      throw failure;
    }
  }

  private IoProviderResult<ReadCompleted> completeRead(
      IoRequest<MemoryAddressableFile.ReadCompleted> positional, long position) {
    return positional.execute().mapSuccess(value -> {
      long nextExamined = Math.addExact(position, value.bytesRead());
      long currentConsumed;
      synchronized (this) {
        examined = nextExamined;
        currentConsumed = consumed;
      }
      return new ReadCompleted(value.buffer(), currentConsumed, nextExamined, value.bytesRead());
    });
  }

  private IoProviderResult<WriteCompleted> completeWrite(
      IoRequest<MemoryAddressableFile.WriteCompleted> positional, long position) {
    return positional.execute().mapSuccess(value -> {
      long next = Math.addExact(position, value.bytesWritten());
      synchronized (this) {
        consumed = next;
        examined = next;
      }
      return new WriteCompleted(value.buffer(), next, value.bytesWritten());
    });
  }

  private synchronized void release(IoRequest<?> positional) {
    try {
      positional.releaseResources();
    } finally {
      pending = false;
    }
  }

  private void requireIdle() {
    if (pending) {
      throw new IllegalStateException("sequential cursor is held by a live request");
    }
  }

}
