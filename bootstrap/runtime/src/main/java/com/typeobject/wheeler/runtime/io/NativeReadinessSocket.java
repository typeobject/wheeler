package com.typeobject.wheeler.runtime.io;

import java.io.IOException;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicInteger;

/** Bounded nonblocking socket capability driven by the portable readiness lifecycle. */
public final class NativeReadinessSocket implements AutoCloseable {
  /** Successful nonblocking receive with exact owner and progress. */
  public static final class ReadCompleted {
    private final OwnedIoBuffer buffer;
    private final int bufferOffset;
    private final int bytesRead;

    private ReadCompleted(OwnedIoBuffer buffer, int bufferOffset, int bytesRead) {
      this.buffer = buffer;
      this.bufferOffset = bufferOffset;
      this.bytesRead = bytesRead;
    }

    public OwnedIoBuffer buffer() {
      return buffer;
    }

    public int bufferOffset() {
      return bufferOffset;
    }

    public int bytesRead() {
      return bytesRead;
    }
  }

  /** Successful nonblocking send with exact owner and progress. */
  public static final class WriteCompleted {
    private final OwnedIoBuffer buffer;
    private final int bufferOffset;
    private final int bytesWritten;

    private WriteCompleted(OwnedIoBuffer buffer, int bufferOffset, int bytesWritten) {
      this.buffer = buffer;
      this.bufferOffset = bufferOffset;
      this.bytesWritten = bytesWritten;
    }

    public OwnedIoBuffer buffer() {
      return buffer;
    }

    public int bufferOffset() {
      return bufferOffset;
    }

    public int bytesWritten() {
      return bytesWritten;
    }
  }

  private static final int MAX_TRANSFER_BYTES = 1024 * 1024;

  private final String identity;
  private final SocketChannel channel;
  private final Selector selector;
  private final SelectionKey key;
  private final AtomicInteger activeRequests = new AtomicInteger();
  private boolean closed;

  private NativeReadinessSocket(
      String identity,
      SocketChannel channel,
      Selector selector,
      SelectionKey key) {
    this.identity = DurabilitySubject.visibleAscii("identity", identity, 160, false);
    this.channel = channel;
    this.selector = selector;
    this.key = key;
  }

  /** Establishes one connected socket capability, then switches it to nonblocking mode. */
  public static NativeReadinessSocket connect(String identity, SocketAddress address)
      throws IOException {
    Objects.requireNonNull(address, "address");
    SocketChannel channel = SocketChannel.open(address);
    Selector selector = null;
    try {
      channel.configureBlocking(false);
      selector = Selector.open();
      SelectionKey key = channel.register(selector, 0);
      return new NativeReadinessSocket(identity, channel, selector, key);
    } catch (Throwable failure) {
      channel.close();
      if (selector != null) {
        selector.close();
      }
      throw failure;
    }
  }

  /** Prepares one readiness-gated nonblocking receive without reading the socket. */
  public synchronized IoRequest<ReadCompleted> read(
      OwnedIoBuffer destination, int bufferOffset, int length) {
    requireOpen();
    Objects.requireNonNull(destination, "destination");
    checkRange(destination, bufferOffset, length);
    destination.hold();
    activeRequests.incrementAndGet();
    try {
      return IoRequest.prepareWhen(
          identity + ":read:" + bufferOffset + ":" + length,
          Math.max(1, length),
          () -> ready(SelectionKey.OP_READ),
          () -> executeRead(destination, bufferOffset, length),
          () -> release(destination));
    } catch (RuntimeException failure) {
      release(destination);
      throw failure;
    }
  }

  /** Prepares one readiness-gated nonblocking send without writing the socket. */
  public synchronized IoRequest<WriteCompleted> write(
      OwnedIoBuffer source, int bufferOffset, int length) {
    requireOpen();
    Objects.requireNonNull(source, "source");
    checkRange(source, bufferOffset, length);
    source.hold();
    activeRequests.incrementAndGet();
    try {
      return IoRequest.prepareWhen(
          identity + ":write:" + bufferOffset + ":" + length,
          Math.max(1, length),
          () -> ready(SelectionKey.OP_WRITE),
          () -> executeWrite(source, bufferOffset, length),
          () -> release(source));
    } catch (RuntimeException failure) {
      release(source);
      throw failure;
    }
  }

  public String identity() {
    return identity;
  }

  public synchronized void shutdownOutput() throws IOException {
    requireOpen();
    channel.shutdownOutput();
  }

  @Override
  public synchronized void close() throws IOException {
    if (closed) {
      return;
    }
    if (activeRequests.get() != 0) {
      throw new IllegalStateException("native socket has unreaped request resources");
    }
    closed = true;
    key.cancel();
    channel.close();
    selector.close();
  }

  private synchronized boolean ready(int operation) {
    if (closed || !key.isValid()) {
      return false;
    }
    try {
      key.interestOps(operation);
      selector.selectNow();
      boolean ready = key.isValid() && (key.readyOps() & operation) != 0;
      selector.selectedKeys().clear();
      if (key.isValid()) {
        key.interestOps(0);
      }
      return ready;
    } catch (IOException | RuntimeException failure) {
      return false;
    }
  }

  private IoProviderResult<ReadCompleted> executeRead(
      OwnedIoBuffer destination, int bufferOffset, int length) {
    byte[] bytes = new byte[length];
    try {
      int read = channel.read(ByteBuffer.wrap(bytes));
      if (read < 0) {
        read = 0;
      }
      destination.copyFrom(bytes, 0, bufferOffset, read);
      return IoProviderResult.success(new ReadCompleted(destination, bufferOffset, read), read);
    } catch (IOException failure) {
      return IoProviderResult.failure("native socket read failed", 0);
    }
  }

  private IoProviderResult<WriteCompleted> executeWrite(
      OwnedIoBuffer source, int bufferOffset, int length) {
    byte[] bytes = new byte[length];
    source.copyTo(bufferOffset, bytes, 0, length);
    try {
      int written = channel.write(ByteBuffer.wrap(bytes));
      return IoProviderResult.success(
          new WriteCompleted(source, bufferOffset, written), written);
    } catch (IOException failure) {
      return IoProviderResult.failure("native socket write failed", 0);
    }
  }

  private synchronized void release(OwnedIoBuffer buffer) {
    buffer.release();
    if (activeRequests.decrementAndGet() < 0) {
      throw new IllegalStateException("native socket request accounting underflow");
    }
  }

  private void checkRange(OwnedIoBuffer buffer, int offset, int length) {
    int capacity = buffer.length();
    if (offset < 0 || length < 0 || MAX_TRANSFER_BYTES < length
        || capacity < offset || capacity - offset < length) {
      throw new IllegalArgumentException("socket buffer range is outside its capability");
    }
  }

  private void requireOpen() {
    if (closed) {
      throw new IllegalStateException("native socket capability is closed");
    }
  }
}
