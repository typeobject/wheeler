package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;

/** Runs the declared bounded loopback-network and physical multi-queue storage profile. */
final class HostIoProfileTest {
  private static final int CONNECTIONS = 256;
  private static final int STORAGE_QUEUES = 4;
  private static final int STORAGE_REQUESTS = 64;

  @Test
  void oneWorkerServicesTwoHundredFiftySixLiveLoopbackConnections() throws Exception {
    List<SocketChannel> clients = new ArrayList<>();
    try (ServerSocketChannel listener = ServerSocketChannel.open();
        ExecutorService worker = Executors.newSingleThreadExecutor()) {
      listener.bind(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0), CONNECTIONS);
      InetSocketAddress address = (InetSocketAddress) listener.getLocalAddress();
      Future<Integer> observed = worker.submit(() -> acceptAndRead(listener));
      for (int connection = 0; connection < CONNECTIONS; connection++) {
        SocketChannel client = SocketChannel.open();
        client.connect(address);
        clients.add(client);
      }
      for (int connection = 0; connection < clients.size(); connection++) {
        ByteBuffer value = ByteBuffer.wrap(new byte[] {(byte) connection});
        while (value.hasRemaining()) {
          clients.get(connection).write(value);
        }
      }
      assertEquals(CONNECTIONS, observed.get(5, TimeUnit.SECONDS));
    } finally {
      for (SocketChannel client : clients) {
        client.close();
      }
    }
  }

  @Test
  void fourPhysicalFileQueuesPassTheCommonPositionalCompletionLifecycle() throws Exception {
    Path root = Files.createTempDirectory("wheeler-io-profile-");
    List<FileChannel> channels = new ArrayList<>();
    try {
      for (int queue = 0; queue < STORAGE_QUEUES; queue++) {
        channels.add(FileChannel.open(
            root.resolve("queue-" + queue + ".bin"),
            StandardOpenOption.CREATE_NEW,
            StandardOpenOption.READ,
            StandardOpenOption.WRITE));
      }
      IoLimits limits = new IoLimits(64, 64, 64, 64, 128, 64);
      try (ThreadedIo io = new ThreadedIo(STORAGE_QUEUES, STORAGE_REQUESTS);
          IoScope scope = io.scope(limits)) {
        List<IoRequest<Integer>> requests = new ArrayList<>();
        for (int request = 0; request < STORAGE_REQUESTS; request++) {
          int selected = request;
          requests.add(IoRequest.prepare(
              "host-storage:" + request,
              1,
              () -> writeOne(channels.get(selected % STORAGE_QUEUES), selected)));
        }
        List<IoOperation<Integer>> operations = scope.submitBatch(requests);
        for (int request = 0; request < operations.size(); request++) {
          IoCompletion<Integer> completion = operations.get(request).await();
          assertEquals(1, completion.value());
          assertEquals(1, completion.progress());
          assertTrue(completion.resourcesReleased());
        }
      }
      for (int queue = 0; queue < STORAGE_QUEUES; queue++) {
        ByteBuffer data = ByteBuffer.allocate(STORAGE_REQUESTS / STORAGE_QUEUES);
        int read = channels.get(queue).read(data, 0);
        assertEquals(data.capacity(), read);
        for (int offset = 0; offset < data.capacity(); offset++) {
          assertEquals((byte) (queue + offset * STORAGE_QUEUES), data.array()[offset]);
        }
      }
    } finally {
      for (FileChannel channel : channels) {
        channel.close();
      }
      try (var paths = Files.walk(root)) {
        for (Path path : paths.sorted(java.util.Comparator.reverseOrder()).toList()) {
          Files.delete(path);
        }
      }
    }
  }

  private static int acceptAndRead(ServerSocketChannel listener) throws Exception {
    List<SocketChannel> accepted = new ArrayList<>();
    try {
      for (int connection = 0; connection < CONNECTIONS; connection++) {
        accepted.add(listener.accept());
      }
      int complete = 0;
      for (SocketChannel channel : accepted) {
        ByteBuffer value = ByteBuffer.allocate(1);
        while (value.hasRemaining()) {
          if (channel.read(value) < 0) {
            throw new IllegalStateException("loopback connection closed before its byte");
          }
        }
        complete++;
      }
      return complete;
    } finally {
      for (SocketChannel channel : accepted) {
        channel.close();
      }
    }
  }

  private static IoProviderResult<Integer> writeOne(FileChannel channel, int request) {
    int queue = request % STORAGE_QUEUES;
    int offset = request / STORAGE_QUEUES;
    ByteBuffer value = ByteBuffer.wrap(new byte[] {(byte) request});
    try {
      while (value.hasRemaining()) {
        channel.write(value, offset);
      }
      return IoProviderResult.success(1, 1);
    } catch (java.io.IOException failure) {
      return IoProviderResult.failure("host-storage-write:" + queue, 0);
    }
  }
}
