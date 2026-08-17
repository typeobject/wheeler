package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Tests sparse immutable signed-word storage. */
final class PersistentLongListTest {
  @Test
  void zeroListsAllocateChunksOnlyThroughImmutableUpdates() {
    List<Long> zeros = PersistentLongList.zeros(1_000_000);

    assertEquals(1_000_000, zeros.size());
    assertEquals(0L, zeros.get(0));
    assertEquals(0L, zeros.get(999_999));

    List<Long> updated = PersistentLongList.with(zeros, 999_999, 7);
    assertEquals(0L, zeros.get(999_999));
    assertEquals(7L, updated.get(999_999));
    assertEquals(0L, updated.get(999_998));
  }

  @Test
  void threeWordUpdatesCrossSparseChunkBoundaries() {
    List<Long> zeros = PersistentLongList.zeros(128);

    List<Long> updated = PersistentLongList.withThree(zeros, 63, 4, 5, 6);

    assertEquals(0L, zeros.get(63));
    assertEquals(4L, updated.get(63));
    assertEquals(5L, updated.get(64));
    assertEquals(6L, updated.get(65));
    assertEquals(0L, updated.get(66));
  }

  @Test
  void rejectsNegativeSizes() {
    assertThrows(IllegalArgumentException.class, () -> PersistentLongList.zeros(-1));
  }
}
