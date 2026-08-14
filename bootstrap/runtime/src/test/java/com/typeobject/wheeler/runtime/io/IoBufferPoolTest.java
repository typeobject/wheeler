package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.MemoryAddressableFile.Rights;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Conformance evidence for bounded registered and provider-supplied buffer ownership. */
final class IoBufferPoolTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 4, 4, 8, 64);

  @Test
  void saturationRetainsCancellationRecycleAndCloseControl() {
    IoBufferPool pool = new IoBufferPool(2, 4);
    IoBufferPool.Lease first = pool.acquire().orElseThrow();
    IoBufferPool.Lease second = pool.acquire().orElseThrow();
    assertEquals(java.util.Optional.empty(), pool.acquire());
    assertEquals(0, pool.availableCount());
    assertThrows(IllegalStateException.class, pool::close);

    MemoryAddressableFile file = new MemoryAddressableFile(
        "provided-cancel", Rights.READ_ONLY, new byte[] {1, 2, 3, 4});
    IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS);
    IoRequest<IoBufferPool.ReadCompleted> request = pool.readAt(file, 0, first, 0, 4);
    assertThrows(IllegalStateException.class, () -> pool.readAt(file, 0, first, 0, 1));
    IoOperation<IoBufferPool.ReadCompleted> operation = scope.submit(request);
    assertThrows(IllegalStateException.class, first::snapshot);
    assertThrows(IllegalStateException.class, () -> pool.recycle(first));

    operation.cancel();
    operation.await();
    assertArrayEquals(new byte[4], first.snapshot());
    pool.recycle(first);
    assertEquals(1, pool.availableCount());
    assertThrows(IllegalStateException.class, first::snapshot);
    pool.recycle(second);
    assertEquals(2, pool.availableCount());
    scope.close();
    pool.close();
  }

  @Test
  void providedReadsReturnTheExactLeaseOnlyAfterTerminalRelease() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "provided-read", Rights.READ_ONLY, "data".getBytes(StandardCharsets.US_ASCII));
    IoBufferPool pool = new IoBufferPool(1, 4);
    IoBufferPool.Lease lease = pool.acquire().orElseThrow();
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      IoBufferPool.ReadCompleted completed =
          scope.await(pool.readAt(file, 0, lease, 0, 4)).value();
      assertSame(lease, completed.lease());
      assertEquals(0, completed.position());
      assertEquals(4, completed.bytesRead());
      assertArrayEquals("data".getBytes(StandardCharsets.US_ASCII), lease.snapshot());
    }
    pool.recycle(lease);
    pool.close();
  }

  @Test
  void registeredWritesNeedTerminalReusePermissionAndNoStagingOwner() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "registered-write", Rights.READ_WRITE, new byte[4]);
    IoBufferPool pool = new IoBufferPool(1, 2);
    IoBufferPool.Lease lease = pool.acquire().orElseThrow();
    lease.put(0, (byte) 9);
    lease.put(1, (byte) 8);
    IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS);
    IoOperation<IoBufferPool.WriteCompleted> operation =
        scope.submit(pool.writeAt(file, 1, lease, 0, 2));
    assertThrows(IllegalStateException.class, () -> pool.recycle(lease));

    IoBufferPool.WriteCompleted completed = operation.await().value();
    assertSame(lease, completed.lease());
    assertEquals(2, completed.bytesWritten());
    assertArrayEquals(new byte[] {9, 8}, lease.snapshot());
    pool.recycle(lease);
    assertThrows(IllegalStateException.class, lease::snapshot);

    IoBufferPool.Lease reused = pool.acquire().orElseThrow();
    assertArrayEquals(new byte[] {9, 8}, reused.snapshot());
    pool.recycle(reused);
    OwnedIoBuffer observed = OwnedIoBuffer.allocate(4);
    scope.await(file.readAt(0, observed, 0, 4));
    assertArrayEquals(new byte[] {0, 9, 8, 0}, observed.snapshot());
    scope.close();
    pool.close();
  }

  @Test
  void rejectsInvalidPoolBoundsAndForeignLeases() {
    assertThrows(IllegalArgumentException.class, () -> new IoBufferPool(0, 1));
    assertThrows(IllegalArgumentException.class, () -> new IoBufferPool(1, 0));
    assertThrows(IllegalArgumentException.class, () -> new IoBufferPool(2, 16 * 1024 * 1024));
    IoBufferPool first = new IoBufferPool(1, 1);
    IoBufferPool second = new IoBufferPool(1, 1);
    IoBufferPool.Lease lease = first.acquire().orElseThrow();
    assertThrows(IllegalStateException.class, () -> second.recycle(lease));
    first.recycle(lease);
    first.close();
    second.close();
  }
}
