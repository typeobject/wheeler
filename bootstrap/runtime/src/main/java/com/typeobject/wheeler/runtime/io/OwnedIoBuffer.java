package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Bounded affine byte buffer inaccessible while captured by a live request. */
public final class OwnedIoBuffer {
  private static final int MAX_BUFFER_BYTES = 16 * 1024 * 1024;

  private final byte[] bytes;
  private boolean held;

  private OwnedIoBuffer(byte[] bytes) {
    if (bytes.length > MAX_BUFFER_BYTES) {
      throw new IllegalArgumentException("I/O buffer exceeds 16 MiB");
    }
    this.bytes = bytes;
  }

  /** Allocates one zero-filled owned buffer. */
  public static OwnedIoBuffer allocate(int length) {
    if (length < 0 || length > MAX_BUFFER_BYTES) {
      throw new IllegalArgumentException("I/O buffer length is out of bounds");
    }
    return new OwnedIoBuffer(new byte[length]);
  }

  /** Copies caller bytes into one independent owned buffer. */
  public static OwnedIoBuffer copyOf(byte[] bytes) {
    Objects.requireNonNull(bytes, "bytes");
    return new OwnedIoBuffer(bytes.clone());
  }

  /** Returns the fixed buffer length while caller ownership is available. */
  public synchronized int length() {
    requireOwned();
    return bytes.length;
  }

  /** Replaces one byte while caller ownership is available. */
  public synchronized void put(int index, byte value) {
    requireOwned();
    bytes[index] = value;
  }

  /** Returns one byte while caller ownership is available. */
  public synchronized byte get(int index) {
    requireOwned();
    return bytes[index];
  }

  /** Returns an independent snapshot while caller ownership is available. */
  public synchronized byte[] snapshot() {
    requireOwned();
    return bytes.clone();
  }

  synchronized void hold() {
    if (held) {
      throw new IllegalStateException("I/O buffer is already held by a request");
    }
    held = true;
  }

  synchronized void release() {
    if (!held) {
      throw new IllegalStateException("I/O buffer is not held by a request");
    }
    held = false;
  }

  synchronized void copyFrom(byte[] source, int sourceOffset, int destinationOffset, int length) {
    requireHeld();
    System.arraycopy(source, sourceOffset, bytes, destinationOffset, length);
  }

  synchronized void copyTo(int sourceOffset, byte[] destination, int destinationOffset, int length) {
    requireHeld();
    System.arraycopy(bytes, sourceOffset, destination, destinationOffset, length);
  }

  private void requireOwned() {
    if (held) {
      throw new IllegalStateException("I/O buffer is held until terminal resource release");
    }
  }

  private void requireHeld() {
    if (!held) {
      throw new IllegalStateException("provider accessed an unheld I/O buffer");
    }
  }
}
