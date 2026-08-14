package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.DirectFile.Requirement;
import com.typeobject.wheeler.runtime.io.DirectFile.TailPolicy;
import com.typeobject.wheeler.runtime.io.MemoryAddressableFile.Rights;
import org.junit.jupiter.api.Test;

/** Conformance evidence for explicit direct-I/O alignment, fallback, and coherence. */
final class DirectFileTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 4, 4, 8, 64);

  @Test
  void requiredDirectPathRejectsUnavailableOrUnalignedRequests() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "direct-required", Rights.READ_WRITE, new byte[16]);
    assertThrows(
        IllegalStateException.class,
        () -> new DirectFile(file, 4, Requirement.REQUIRED, TailPolicy.REJECT, false));
    DirectFile direct = new DirectFile(
        file, 4, Requirement.REQUIRED, TailPolicy.REJECT, true);
    assertEquals(4, direct.alignment());
    assertThrows(
        IllegalArgumentException.class,
        () -> direct.readAt(1, OwnedIoBuffer.allocate(4), 0, 4));
    assertThrows(
        IllegalArgumentException.class,
        () -> direct.writeAt(0, OwnedIoBuffer.allocate(4), 0, 3));
  }

  @Test
  void preferredFallbackIsExplicitAndTailPolicyNeverDegradesSilently() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "direct-preferred", Rights.READ_WRITE, new byte[8]);
    DirectFile strictPreferred = new DirectFile(
        file, 4, Requirement.PREFERRED, TailPolicy.REJECT, false);
    assertThrows(
        IllegalArgumentException.class,
        () -> strictPreferred.readAt(0, OwnedIoBuffer.allocate(4), 0, 4));

    DirectFile fallback = new DirectFile(
        file, 4, Requirement.PREFERRED, TailPolicy.BUFFERED_FALLBACK, false);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {4, 3, 2});
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      DirectFile.WriteCompleted completed = scope.await(fallback.writeAt(1, source, 0, 3)).value();
      assertFalse(completed.direct());
      assertEquals(3, completed.bytesWritten());
    }
  }

  @Test
  void directAndBufferedViewsShareOneCoherentByteAuthority() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "direct-coherent", Rights.READ_WRITE, new byte[8]);
    DirectFile direct = new DirectFile(
        file, 4, Requirement.REQUIRED, TailPolicy.REJECT, true);
    OwnedIoBuffer directSource = OwnedIoBuffer.copyOf(new byte[] {1, 2, 3, 4});
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      DirectFile.WriteCompleted written =
          scope.await(direct.writeAt(0, directSource, 0, 4)).value();
      assertTrue(written.direct());
      OwnedIoBuffer bufferedRead = OwnedIoBuffer.allocate(4);
      scope.await(file.readAt(0, bufferedRead, 0, 4));
      assertArrayEquals(new byte[] {1, 2, 3, 4}, bufferedRead.snapshot());

      OwnedIoBuffer bufferedSource = OwnedIoBuffer.copyOf(new byte[] {9, 8, 7, 6});
      scope.await(file.writeAt(4, bufferedSource, 0, 4));
      OwnedIoBuffer directRead = OwnedIoBuffer.allocate(4);
      DirectFile.ReadCompleted read = scope.await(direct.readAt(4, directRead, 0, 4)).value();
      assertTrue(read.direct());
      assertArrayEquals(new byte[] {9, 8, 7, 6}, directRead.snapshot());
    }
  }
}
