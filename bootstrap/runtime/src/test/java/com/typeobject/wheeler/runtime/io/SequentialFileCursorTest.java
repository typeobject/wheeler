package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.MemoryAddressableFile.Rights;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Conformance evidence for the single-owner sequential positional-file adapter. */
final class SequentialFileCursorTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 4, 4, 8, 64);

  @Test
  void readsPreserveIndependentConsumedAndExaminedPositions() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "sequential-read", Rights.READ_ONLY, "abcdef".getBytes(StandardCharsets.US_ASCII));
    SequentialFileCursor cursor = new SequentialFileCursor(file);
    OwnedIoBuffer first = OwnedIoBuffer.allocate(4);
    IoRequest<SequentialFileCursor.ReadCompleted> request = cursor.read(first, 0, 4);

    assertThrows(IllegalStateException.class, cursor::consumedPosition);
    assertThrows(
        IllegalStateException.class,
        () -> cursor.read(OwnedIoBuffer.allocate(1), 0, 1));
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      SequentialFileCursor.ReadCompleted completed = scope.await(request).value();
      assertEquals(0, completed.consumedPosition());
      assertEquals(4, completed.examinedPosition());
      assertEquals(4, completed.bytesRead());
      assertArrayEquals("abcd".getBytes(StandardCharsets.US_ASCII), first.snapshot());
    }

    assertEquals(0, cursor.consumedPosition());
    assertEquals(4, cursor.examinedPosition());
    cursor.advance(2, 3);
    assertEquals(2, cursor.consumedPosition());
    assertEquals(3, cursor.examinedPosition());
    assertThrows(IllegalArgumentException.class, () -> cursor.advance(1, 3));

    OwnedIoBuffer second = OwnedIoBuffer.allocate(2);
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      SequentialFileCursor.ReadCompleted completed = scope.await(cursor.read(second, 0, 2)).value();
      assertEquals(2, completed.consumedPosition());
      assertEquals(5, completed.examinedPosition());
      assertArrayEquals("de".getBytes(StandardCharsets.US_ASCII), second.snapshot());
    }
  }

  @Test
  void cancellationBeforeEffectReleasesCursorWithoutAdvancingIt() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "sequential-cancel", Rights.READ_ONLY, new byte[] {1, 2, 3});
    SequentialFileCursor cursor = new SequentialFileCursor(file);
    OwnedIoBuffer destination = OwnedIoBuffer.allocate(2);
    IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS);
    IoOperation<SequentialFileCursor.ReadCompleted> operation =
        scope.submit(cursor.read(destination, 0, 2));

    operation.cancel();
    operation.await();

    assertEquals(0, cursor.consumedPosition());
    assertEquals(0, cursor.examinedPosition());
    assertArrayEquals(new byte[2], destination.snapshot());
    scope.close();
  }

  @Test
  void sequentialWritesAdvanceOneSettledPosition() {
    MemoryAddressableFile file = new MemoryAddressableFile(
        "sequential-write", Rights.READ_WRITE, new byte[4]);
    SequentialFileCursor cursor = new SequentialFileCursor(file);
    OwnedIoBuffer source = OwnedIoBuffer.copyOf(new byte[] {9, 8});
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      SequentialFileCursor.WriteCompleted completed = scope.await(cursor.write(source, 0, 2)).value();
      assertEquals(2, completed.position());
      assertEquals(2, completed.bytesWritten());
    }

    assertEquals(2, cursor.consumedPosition());
    assertEquals(2, cursor.examinedPosition());
    OwnedIoBuffer written = OwnedIoBuffer.allocate(2);
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      scope.await(file.readAt(0, written, 0, 2));
    }
    assertArrayEquals(new byte[] {9, 8}, written.snapshot());

    OwnedIoBuffer destination = OwnedIoBuffer.allocate(2);
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      scope.await(cursor.read(destination, 0, 2));
    }
    assertArrayEquals(new byte[2], destination.snapshot());
    assertThrows(
        IllegalStateException.class,
        () -> cursor.write(OwnedIoBuffer.allocate(1), 0, 1));
  }
}
