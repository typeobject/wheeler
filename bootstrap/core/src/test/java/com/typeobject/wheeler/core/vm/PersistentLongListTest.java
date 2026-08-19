package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Tests sparse persistent and committed signed-word storage. */
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
  void committedUpdatesFreezeToIndependentPersistentCopies() {
    List<Long> values = PersistentLongList.zeros(128);
    values = PersistentLongList.withCommitted(values, 63, 4);
    List<Long> snapshot = PersistentLongList.persistentCopy(values);

    values = PersistentLongList.withThreeCommitted(values, 63, 7, 8, 9);

    assertEquals(4L, snapshot.get(63));
    assertEquals(0L, snapshot.get(64));
    assertEquals(7L, values.get(63));
    assertEquals(8L, values.get(64));
    assertEquals(9L, values.get(65));
  }

  @Test
  void rejectsNegativeSizes() {
    assertThrows(IllegalArgumentException.class, () -> PersistentLongList.zeros(-1));
  }
}
