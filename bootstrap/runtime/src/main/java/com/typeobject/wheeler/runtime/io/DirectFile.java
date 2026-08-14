package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Explicit aligned direct-I/O profile over one coherent positional file capability. */
public final class DirectFile {
  /** Whether absence of a direct path rejects the operation or permits reported fallback. */
  public enum Requirement {
    REQUIRED,
    PREFERRED
  }

  /** Closed policy for a request that does not cover complete aligned blocks. */
  public enum TailPolicy {
    REJECT,
    BUFFERED_FALLBACK
  }

  /** Terminal direct-profile read result. */
  public record ReadCompleted(
      OwnedIoBuffer buffer,
      long position,
      int bufferOffset,
      int bytesRead,
      boolean direct) {}

  /** Terminal direct-profile write result. */
  public record WriteCompleted(
      OwnedIoBuffer buffer,
      long position,
      int bufferOffset,
      int bytesWritten,
      boolean direct) {}

  private final MemoryAddressableFile file;
  private final int alignment;
  private final Requirement requirement;
  private final TailPolicy tailPolicy;
  private final boolean backendDirect;

  public DirectFile(
      MemoryAddressableFile file,
      int alignment,
      Requirement requirement,
      TailPolicy tailPolicy,
      boolean backendDirect) {
    this.file = Objects.requireNonNull(file, "file");
    if (alignment < 1 || alignment > 4_096 || Integer.bitCount(alignment) != 1) {
      throw new IllegalArgumentException("direct-I/O alignment must be a power of two up to 4096");
    }
    this.alignment = alignment;
    this.requirement = Objects.requireNonNull(requirement, "requirement");
    this.tailPolicy = Objects.requireNonNull(tailPolicy, "tailPolicy");
    this.backendDirect = backendDirect;
    if (requirement == Requirement.REQUIRED && !backendDirect) {
      throw new IllegalStateException("required direct-I/O path is unavailable");
    }
  }

  /** Prepares an aligned direct read or one explicitly reported preferred fallback. */
  public IoRequest<ReadCompleted> readAt(
      long position, OwnedIoBuffer destination, int bufferOffset, int length) {
    boolean direct = path(position, bufferOffset, length);
    IoRequest<MemoryAddressableFile.ReadCompleted> positional =
        file.readAt(position, destination, bufferOffset, length);
    try {
      return IoRequest.prepare(
          positional.identity() + (direct ? ":direct" : ":buffered-fallback"),
          positional.work(),
          () -> positional.execute().mapSuccess(value -> new ReadCompleted(
              value.buffer(),
              value.position(),
              value.bufferOffset(),
              value.bytesRead(),
              direct)),
          positional::releaseResources);
    } catch (RuntimeException failure) {
      positional.releaseResources();
      throw failure;
    }
  }

  /** Prepares an aligned direct write or one explicitly reported preferred fallback. */
  public IoRequest<WriteCompleted> writeAt(
      long position, OwnedIoBuffer source, int bufferOffset, int length) {
    boolean direct = path(position, bufferOffset, length);
    IoRequest<MemoryAddressableFile.WriteCompleted> positional =
        file.writeAt(position, source, bufferOffset, length);
    try {
      return IoRequest.prepare(
          positional.identity() + (direct ? ":direct" : ":buffered-fallback"),
          positional.work(),
          () -> positional.execute().mapSuccess(value -> new WriteCompleted(
              value.buffer(),
              value.position(),
              value.bufferOffset(),
              value.bytesWritten(),
              direct)),
          positional::releaseResources);
    } catch (RuntimeException failure) {
      positional.releaseResources();
      throw failure;
    }
  }

  public int alignment() {
    return alignment;
  }

  private boolean path(long position, int bufferOffset, int length) {
    boolean aligned = position >= 0
        && position % alignment == 0
        && bufferOffset >= 0
        && bufferOffset % alignment == 0
        && length >= 0
        && length % alignment == 0;
    if (backendDirect && aligned) {
      return true;
    }
    if (requirement == Requirement.REQUIRED
        || tailPolicy == TailPolicy.REJECT) {
      throw new IllegalArgumentException(
          backendDirect
              ? "direct-I/O position, buffer offset, and length must be aligned"
              : "direct-I/O fallback is forbidden by policy");
    }
    return false;
  }
}
