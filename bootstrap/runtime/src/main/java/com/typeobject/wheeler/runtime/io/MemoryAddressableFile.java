package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Bounded in-memory oracle for positional I/O capability semantics. */
public final class MemoryAddressableFile {
  private static final int MAX_FILE_BYTES = 16 * 1024 * 1024;

  /** Rights fixed when the capability is created. */
  public enum Rights {
    READ_ONLY,
    READ_WRITE
  }

  /** Terminal positional read result returning the destination owner. */
  public record ReadCompleted(
      OwnedIoBuffer buffer, long position, int bufferOffset, int bytesRead) {}

  /** Terminal positional write result returning the source owner. */
  public record WriteCompleted(
      OwnedIoBuffer buffer, long position, int bufferOffset, int bytesWritten) {}

  private final String identity;
  private final Rights rights;
  private final byte[] bytes;

  public MemoryAddressableFile(String identity, Rights rights, byte[] initialBytes) {
    this.identity = validateIdentity(identity);
    this.rights = Objects.requireNonNull(rights, "rights");
    Objects.requireNonNull(initialBytes, "initialBytes");
    if (initialBytes.length > MAX_FILE_BYTES) {
      throw new IllegalArgumentException("memory file exceeds 16 MiB");
    }
    bytes = initialBytes.clone();
  }

  /** Prepares a positional read without touching file or destination bytes. */
  public IoRequest<ReadCompleted> readAt(
      long position, OwnedIoBuffer destination, int bufferOffset, int length) {
    Objects.requireNonNull(destination, "destination");
    int bufferLength = destination.length();
    checkRange("destination", bufferOffset, length, bufferLength);
    int start = checkedPosition(position, true);
    int bytesRead = Math.min(length, bytes.length - start);
    destination.hold();
    try {
      String requestIdentity = identity
          + ":read:"
          + position
          + ":"
          + bufferOffset
          + ":"
          + length;
      return IoRequest.prepare(
          requestIdentity,
          Math.max(1, length),
          () -> {
            synchronized (this) {
              destination.copyFrom(bytes, start, bufferOffset, bytesRead);
            }
            return IoTaskResult.success(
                new ReadCompleted(destination, position, bufferOffset, bytesRead),
                bytesRead);
          },
          destination::release);
    } catch (RuntimeException failure) {
      destination.release();
      throw failure;
    }
  }

  /** Prepares one exact positional write without touching file or source bytes. */
  public IoRequest<WriteCompleted> writeAt(
      long position, OwnedIoBuffer source, int bufferOffset, int length) {
    if (rights != Rights.READ_WRITE) {
      throw new IllegalStateException("memory file capability is read-only");
    }
    Objects.requireNonNull(source, "source");
    int bufferLength = source.length();
    checkRange("source", bufferOffset, length, bufferLength);
    int start = checkedPosition(position, length == 0);
    checkRange("file", start, length, bytes.length);
    source.hold();
    try {
      String requestIdentity = identity
          + ":write:"
          + position
          + ":"
          + bufferOffset
          + ":"
          + length;
      return IoRequest.prepare(
          requestIdentity,
          Math.max(1, length),
          () -> {
            synchronized (this) {
              source.copyTo(bufferOffset, bytes, start, length);
            }
            return IoTaskResult.success(
                new WriteCompleted(source, position, bufferOffset, length),
                length);
          },
          source::release);
    } catch (RuntimeException failure) {
      source.release();
      throw failure;
    }
  }

  private int checkedPosition(long position, boolean allowEnd) {
    long upper = allowEnd ? bytes.length : bytes.length - 1L;
    if (position < 0 || position > upper || position > Integer.MAX_VALUE) {
      throw new IllegalArgumentException("file position is outside the capability");
    }
    return Math.toIntExact(position);
  }

  private static void checkRange(String name, int offset, int length, int capacity) {
    if (offset < 0 || length < 0 || offset > capacity || length > capacity - offset) {
      throw new IllegalArgumentException(name + " range is outside its capability");
    }
  }

  private static String validateIdentity(String identity) {
    Objects.requireNonNull(identity, "identity");
    if (identity.isBlank() || identity.length() > 160 || !identity.equals(identity.trim())) {
      throw new IllegalArgumentException("memory file identity must be 1..160 visible ASCII bytes");
    }
    for (int index = 0; index < identity.length(); index++) {
      char value = identity.charAt(index);
      if (value < 0x21 || value > 0x7e) {
        throw new IllegalArgumentException("memory file identity must use visible ASCII");
      }
    }
    return identity;
  }
}
