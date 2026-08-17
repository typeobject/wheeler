package com.typeobject.wheeler.core.vm;

import java.util.AbstractList;
import java.util.List;
import java.util.Objects;
import java.util.RandomAccess;

/** Immutable chunked signed-word list with bounded copy-on-write updates. */
final class PersistentLongList extends AbstractList<Long> implements RandomAccess {
  private static final int CHUNK_SIZE = 64;

  private final int size;
  private final long[][] chunks;

  private PersistentLongList(int size, long[][] chunks) {
    this.size = size;
    this.chunks = chunks;
  }

  static List<Long> copyOf(List<Long> values) {
    Objects.requireNonNull(values, "values");
    if (values instanceof PersistentLongList) {
      return values;
    }
    int size = values.size();
    long[][] chunks = new long[chunkCount(size)][];
    for (int index = 0; index < size; index++) {
      int chunk = index / CHUNK_SIZE;
      if (chunks[chunk] == null) {
        chunks[chunk] = new long[chunkLength(size, chunk)];
      }
      chunks[chunk][index % CHUNK_SIZE] =
          Objects.requireNonNull(values.get(index), "value");
    }
    return new PersistentLongList(size, chunks);
  }

  static List<Long> zeros(int size) {
    if (size < 0) {
      throw new IllegalArgumentException("Negative persistent list size");
    }
    return new PersistentLongList(size, new long[chunkCount(size)][]);
  }

  static List<Long> with(List<Long> values, int index, long value) {
    return requirePersistent(values).with(index, value);
  }

  static List<Long> withThree(
      List<Long> values,
      int firstIndex,
      long firstValue,
      long secondValue,
      long thirdValue) {
    PersistentLongList source = requirePersistent(values);
    source.checkIndex(firstIndex);
    source.checkIndex(Math.addExact(firstIndex, 2));
    long[][] updated = source.chunks.clone();
    int firstChunk = firstIndex / CHUNK_SIZE;
    int lastChunk = (firstIndex + 2) / CHUNK_SIZE;
    updated[firstChunk] = source.copyChunk(firstChunk);
    if (firstChunk != lastChunk) {
      updated[lastChunk] = source.copyChunk(lastChunk);
    }
    updated[firstChunk][firstIndex % CHUNK_SIZE] = firstValue;
    int secondIndex = firstIndex + 1;
    updated[secondIndex / CHUNK_SIZE][secondIndex % CHUNK_SIZE] = secondValue;
    int thirdIndex = firstIndex + 2;
    updated[thirdIndex / CHUNK_SIZE][thirdIndex % CHUNK_SIZE] = thirdValue;
    return new PersistentLongList(source.size, updated);
  }

  @Override
  public Long get(int index) {
    checkIndex(index);
    long[] chunk = chunks[index / CHUNK_SIZE];
    return chunk == null ? 0L : chunk[index % CHUNK_SIZE];
  }

  @Override
  public int size() {
    return size;
  }

  private PersistentLongList with(int index, long value) {
    checkIndex(index);
    int chunk = index / CHUNK_SIZE;
    long[][] updated = chunks.clone();
    updated[chunk] = copyChunk(chunk);
    updated[chunk][index % CHUNK_SIZE] = value;
    return new PersistentLongList(size, updated);
  }

  private long[] copyChunk(int chunk) {
    long[] source = chunks[chunk];
    return source == null ? new long[chunkLength(size, chunk)] : source.clone();
  }

  private static int chunkCount(int size) {
    return (size + CHUNK_SIZE - 1) / CHUNK_SIZE;
  }

  private static int chunkLength(int size, int chunk) {
    return Math.min(CHUNK_SIZE, size - chunk * CHUNK_SIZE);
  }

  private static PersistentLongList requirePersistent(List<Long> values) {
    return (PersistentLongList) copyOf(values);
  }

  private void checkIndex(int index) {
    if (index < 0 || index >= size) {
      throw new IndexOutOfBoundsException("Invalid persistent word index " + index);
    }
  }
}
