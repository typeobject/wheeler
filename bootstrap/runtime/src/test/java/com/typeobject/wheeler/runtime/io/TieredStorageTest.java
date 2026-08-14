package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import com.typeobject.wheeler.runtime.io.TieredStorage.DrainOutcome;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Exercises typed complete and partial tier drains without durability promotion. */
final class TieredStorageTest {
  private static final IoLimits LIMITS = new IoLimits(4, 4, 4, 4, 4, 64);
  private static final TieredStorage.Tier BURST =
      new TieredStorage.Tier("burst", "rack-a", 64);
  private static final TieredStorage.Tier CAPACITY =
      new TieredStorage.Tier("capacity", "rack-b", 64);

  @Test
  void completeDrainRetainsItsSourceLeaseUntilTerminalRelease() {
    byte[] bytes = "abcdef".getBytes(StandardCharsets.UTF_8);
    TieredStorage.Placement source = TieredStorage.place(BURST, bytes);
    StagedData initial = source.evidence();
    IoRequest<TieredStorage.DrainResult> request = TieredStorage.drain(
        source, CAPACITY, bytes.length);
    assertThrows(IllegalStateException.class, source::snapshot);

    try (IoScope scope = new DeterministicIo(Delivery.DELAYED).scope(LIMITS)) {
      IoOperation<TieredStorage.DrainResult> operation = scope.submit(request);
      assertThrows(IllegalStateException.class, source::snapshot);
      TieredStorage.DrainResult result = operation.await().value();
      assertEquals(DrainOutcome.COMPLETE, result.outcome());
      assertEquals(bytes.length, result.placement().bytes());
      assertEquals(initial.contentIdentity(), result.placement().contentIdentity());
      assertEquals(initial.identity(), result.placement().parentIdentity());
      assertTrue(result.sourceRetained());
    }
    assertArrayEquals(bytes, source.snapshot());
  }

  @Test
  void partialDrainReturnsExactPrefixEvidenceAndPreservesTheSource() {
    byte[] bytes = "abcdef".getBytes(StandardCharsets.UTF_8);
    TieredStorage.Placement source = TieredStorage.place(BURST, bytes);
    StagedData initial = source.evidence();
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      IoCompletion<TieredStorage.DrainResult> completion = scope.await(
          TieredStorage.drain(source, CAPACITY, 3));
      TieredStorage.DrainResult result = completion.value();
      assertEquals(DrainOutcome.PARTIAL_FAILURE, result.outcome());
      assertEquals(3, completion.progress());
      assertEquals(3, result.placement().bytes());
      assertEquals(initial.identity(), result.placement().parentIdentity());
      assertNotEquals(initial.contentIdentity(), result.placement().contentIdentity());
    }
    assertArrayEquals(bytes, source.snapshot());
  }

  @Test
  void preflightFailuresCaptureNoSourceLease() {
    TieredStorage.Placement source = TieredStorage.place(
        BURST, "abcdef".getBytes(StandardCharsets.UTF_8));
    TieredStorage.Tier small = new TieredStorage.Tier("small", "rack-c", 2);
    assertThrows(
        IllegalArgumentException.class,
        () -> TieredStorage.drain(source, small, 2));
    assertThrows(
        IllegalArgumentException.class,
        () -> TieredStorage.drain(source, CAPACITY, 7));
    assertArrayEquals("abcdef".getBytes(StandardCharsets.UTF_8), source.snapshot());
  }

  @Test
  void partialEvidenceCannotEqualOrExceedItsSourceExtent() {
    StagedData initial = TieredStorage.place(BURST, new byte[] {1, 2}).evidence();
    assertThrows(
        IllegalArgumentException.class,
        () -> StagedData.partialOf(initial, "capacity", "rack-b", "0".repeat(64), 2));
  }
}
