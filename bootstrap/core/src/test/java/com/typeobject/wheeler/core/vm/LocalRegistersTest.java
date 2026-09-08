package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import org.junit.jupiter.api.Test;

/** Persistent register versions, including unchanged writes and partial chunks. */
final class LocalRegistersTest {
  @Test
  void reusesOnlyUnchangedVersionsAtEveryChunkBoundary() {
    for (int size : new int[] {1, 31, 32, 33, 63, 64, 65, 255, 256}) {
      LocalRegisters initial = LocalRegisters.create(size, List.of());
      for (int index = 0; index < size; index++) {
        assertSame(initial, initial.with(index, 0));
        for (long value : new long[] {Long.MIN_VALUE, -1, 1, Long.MAX_VALUE}) {
          LocalRegisters changed = initial.with(index, value);
          assertNotSame(initial, changed);
          assertSame(changed, changed.with(index, value));
          assertEquals(value, changed.get(index));
          assertEquals(0, initial.get(index));
          assertEquals(initial, changed.with(index, 0));
        }
      }
    }
  }

  @Test
  void retainsIndependentVersionsAcrossSingleAndPairedWrites() {
    Random random = new Random(0x746e27f4);
    List<Long> expected = new ArrayList<>();
    for (int i = 0; i < 65; i++) { expected.add((long) i); }
    LocalRegisters current = LocalRegisters.create(expected.size(), expected);
    List<LocalRegisters> versions = new ArrayList<>();
    List<List<Long>> values = new ArrayList<>();
    for (int step = 0; step < 512; step++) {
      versions.add(current);
      values.add(List.copyOf(expected));
      int first = random.nextInt(expected.size());
      long firstValue = step % 3 == 0 ? expected.get(first) : random.nextLong();
      if (step % 2 == 0) {
        current = current.with(first, firstValue);
        expected.set(first, firstValue);
      } else {
        int second = step % 5 == 0 ? first : random.nextInt(expected.size());
        long secondValue = random.nextLong();
        current = current.withPair(first, firstValue, second, secondValue);
        expected.set(first, firstValue);
        expected.set(second, secondValue);
      }
      assertEquals(expected, current.asList());
    }
    for (int version = 0; version < versions.size(); version++) {
      assertEquals(values.get(version), versions.get(version).asList());
    }
  }

  @Test
  void checksIndicesEvenWhenTheRequestedValueIsUnchanged() {
    for (int size : new int[] {0, 1, 32, 33, 256}) {
      LocalRegisters registers = LocalRegisters.create(size, List.of());
      List<Long> before = registers.asList();
      for (int invalid : new int[] {-1, size, Integer.MIN_VALUE, Integer.MAX_VALUE}) {
        var failure = assertThrows(IndexOutOfBoundsException.class, () -> registers.with(invalid, 0));
        assertEquals("Invalid local register " + invalid, failure.getMessage());
      }
      assertEquals(before, registers.asList());
    }
  }
}
