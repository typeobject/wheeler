package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Native file-backed tier placement and source-retaining drain evidence. */
final class NativeTieredStorageTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 8, 8, 8, 1024);

  @Test
  void nativeDrainCopiesExactContentAndRetainsNominalAncestry(@TempDir Path temporary)
      throws Exception {
    byte[] content = new byte[] {2, 7, 1, 8, 2, 8};
    try (NativeCompletionFile hotFile = NativeCompletionFile.open(
        "native-tier-hot", temporary.resolve("hot.bin"),
        NativeCompletionFile.Rights.READ_WRITE, 1024, 1, 8);
        NativeCompletionFile coldFile = NativeCompletionFile.open(
            "native-tier-cold", temporary.resolve("cold.bin"),
            NativeCompletionFile.Rights.READ_WRITE, 1024, 1, 8)) {
      NativeTieredStorage.Tier hot = new NativeTieredStorage.Tier(
          "hot", "rack-a", 1024, hotFile);
      NativeTieredStorage.Tier cold = new NativeTieredStorage.Tier(
          "cold", "rack-b", 1024, coldFile);
      NativeTieredStorage.Placement source;
      OwnedIoBuffer sourceBuffer = OwnedIoBuffer.copyOf(content);
      try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
        source = scope.await(NativeTieredStorage.place(
            hot, 5, sourceBuffer, 0, content.length)).successfulValue().orElseThrow();
      }
      assertArrayEquals(content, sourceBuffer.snapshot());

      NativeTieredStorage.DrainResult drained;
      try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
        drained = scope.await(NativeTieredStorage.drain(source, cold, 9))
            .successfulValue().orElseThrow();
      }
      assertEquals(TieredStorage.DrainOutcome.COMPLETE, drained.outcome());
      assertTrue(drained.sourceRetained());
      assertEquals(source.evidence().identity(), drained.placement().evidence().parentIdentity());
      assertEquals(source.evidence().contentIdentity(), drained.placement().evidence().contentIdentity());

      OwnedIoBuffer destination = OwnedIoBuffer.allocate(content.length);
      try (IoScope scope = new CompletionIo(1, 8).scope(LIMITS)) {
        assertEquals(
            content.length,
            scope.await(coldFile.readAt(9, destination, 0, content.length)).progress());
      }
      assertArrayEquals(content, destination.snapshot());
    }
  }
}
