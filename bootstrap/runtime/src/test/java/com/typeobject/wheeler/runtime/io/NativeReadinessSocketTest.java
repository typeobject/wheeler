package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Native selector readiness under the common request, completion, and reap contract. */
final class NativeReadinessSocketTest {
  private static final IoLimits LIMITS = new IoLimits(4, 4, 4, 4, 4, 1024);

  @Test
  void selectorGatesProviderWorkAndEchoesThroughPortableCompletions() throws Exception {
    byte[] payload = "selector-ready".getBytes(StandardCharsets.UTF_8);
    AtomicInteger acceptedReads = new AtomicInteger();
    try (ServerSocketChannel server = ServerSocketChannel.open()) {
      server.bind(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0));
      Thread peer = Thread.ofVirtual().start(() -> {
        try (SocketChannel channel = server.accept()) {
          ByteBuffer bytes = ByteBuffer.allocate(payload.length);
          while (bytes.hasRemaining()) {
            if (channel.read(bytes) < 0) {
              throw new IllegalStateException("client closed before request completed");
            }
          }
          acceptedReads.incrementAndGet();
          bytes.flip();
          while (bytes.hasRemaining()) {
            channel.write(bytes);
          }
        } catch (Exception failure) {
          throw new RuntimeException(failure);
        }
      });

      try (NativeReadinessSocket socket = NativeReadinessSocket.connect(
          "native-selector", server.getLocalAddress());
          IoScope writeScope = new ReadinessIo(1, 4).scope(LIMITS)) {
        OwnedIoBuffer source = OwnedIoBuffer.copyOf(payload);
        IoCompletion<NativeReadinessSocket.WriteCompleted> write =
            writeScope.await(socket.write(source, 0, payload.length));
        assertEquals(payload.length, write.progress());
        assertArrayEquals(payload, source.snapshot());
        peer.join();
        assertEquals(1, acceptedReads.get());

        try (IoScope readScope = new ReadinessIo(1, 4).scope(LIMITS)) {
          OwnedIoBuffer destination = OwnedIoBuffer.allocate(payload.length);
          IoCompletion<NativeReadinessSocket.ReadCompleted> read =
              readScope.await(socket.read(destination, 0, payload.length));
          assertEquals(payload.length, read.progress());
          assertArrayEquals(payload, destination.snapshot());
        }
      }
    }
  }

  @Test
  void queuedCancellationRunsNoSocketProviderAndReleasesTheOwner() throws Exception {
    try (ServerSocketChannel server = ServerSocketChannel.open()) {
      server.bind(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0));
      Thread peer = Thread.ofVirtual().start(() -> {
        try (SocketChannel channel = server.accept()) {
          channel.getRemoteAddress();
        } catch (Exception failure) {
          throw new RuntimeException(failure);
        }
      });
      NativeReadinessSocket socket = NativeReadinessSocket.connect(
          "native-selector-cancel", server.getLocalAddress());
      OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {4, 5});
      IoScope scope = new ReadinessIo(1, 4).scope(LIMITS);
      IoOperation<NativeReadinessSocket.WriteCompleted> operation =
          scope.submit(socket.write(source, 0, 2));

      assertThrows(IllegalStateException.class, socket::close);
      assertTrue(operation.cancel());
      assertEquals(
          IoCompletion.CancellationRelation.CANCELED_BEFORE_EFFECT,
          operation.await().cancellationRelation());
      assertArrayEquals(new byte[] {4, 5}, source.snapshot());
      scope.close();
      socket.close();
      peer.join();
    }
  }
}
