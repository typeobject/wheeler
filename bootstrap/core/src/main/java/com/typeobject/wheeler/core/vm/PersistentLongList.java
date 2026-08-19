package com.typeobject.wheeler.core.vm;

import java.util.AbstractList;
import java.util.List;
import java.util.Objects;
import java.util.RandomAccess;

/** Chunked signed-word list with explicit persistent and committed ownership. */
final class PersistentLongList extends AbstractList<Long> implements RandomAccess {
  private static final int CHUNK_SIZE = 64;

  private final int size;
  private final long[][] chunks;
  private final boolean[] committedChunks;

  private PersistentLongList(int size, long[][] chunks, boolean[] committedChunks) {
    this.size = size;
    this.chunks = chunks;
    this.committedChunks = committedChunks;
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
    return new PersistentLongList(size, chunks, null);
  }

  static List<Long> zeros(int size) {
    if (size < 0) {
      throw new IllegalArgumentException("Negative persistent list size");
    }
    return new PersistentLongList(size, new long[chunkCount(size)][], null);
  }

  static List<Long> with(List<Long> values, int index, long value) {
    return requirePersistent(values).with(index, value);
  }

  static List<Long> withCommitted(List<Long> values, int index, long value) {
    return requireShape(values).withCommitted(index, value);
  }

  static List<Long> withThree(
      List<Long> values,
      int firstIndex,
      long firstValue,
      long secondValue,
      long thirdValue) {
    return requirePersistent(values).withThree(
        firstIndex, firstValue, secondValue, thirdValue, false);
  }

  static List<Long> withThreeCommitted(
      List<Long> values,
      int firstIndex,
      long firstValue,
      long secondValue,
      long thirdValue) {
    return requireShape(values).withThree(
        firstIndex, firstValue, secondValue, thirdValue, true);
  }

  static List<Long> persistentCopy(List<Long> values) {
    return requirePersistent(values);
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
    return new PersistentLongList(size, updated, null);
  }

  private PersistentLongList withCommitted(int index, long value) {
    checkIndex(index);
    PersistentLongList target = committedOwner();
    int chunk = index / CHUNK_SIZE;
    target.own(chunk);
    target.chunks[chunk][index % CHUNK_SIZE] = value;
    return target;
  }

  private PersistentLongList withThree(
      int firstIndex,
      long firstValue,
      long secondValue,
      long thirdValue,
      boolean committedUpdate) {
    checkIndex(firstIndex);
    checkIndex(Math.addExact(firstIndex, 2));
    PersistentLongList target = committedUpdate ? committedOwner() : this;
    int firstChunk = firstIndex / CHUNK_SIZE;
    int lastChunk = (firstIndex + 2) / CHUNK_SIZE;
    long[][] updated = target.chunks;
    if (committedUpdate) {
      target.own(firstChunk);
      target.own(lastChunk);
    } else {
      updated = chunks.clone();
      updated[firstChunk] = copyChunk(firstChunk);
      if (firstChunk != lastChunk) {
        updated[lastChunk] = copyChunk(lastChunk);
      }
    }
    updated[firstChunk][firstIndex % CHUNK_SIZE] = firstValue;
    int secondIndex = firstIndex + 1;
    updated[secondIndex / CHUNK_SIZE][secondIndex % CHUNK_SIZE] = secondValue;
    int thirdIndex = firstIndex + 2;
    updated[thirdIndex / CHUNK_SIZE][thirdIndex % CHUNK_SIZE] = thirdValue;
    return committedUpdate ? target : new PersistentLongList(size, updated, null);
  }

  private PersistentLongList committedOwner() {
    return committedChunks == null
        ? new PersistentLongList(size, chunks.clone(), new boolean[chunks.length])
        : this;
  }

  private PersistentLongList persistentOwner() {
    if (committedChunks == null) {
      return this;
    }
    long[][] copy = chunks.clone();
    for (int chunk = 0; chunk < copy.length; chunk++) {
      if (copy[chunk] != null) {
        copy[chunk] = copy[chunk].clone();
      }
    }
    return new PersistentLongList(size, copy, null);
  }

  private void own(int chunk) {
    if (!committedChunks[chunk]) {
      chunks[chunk] = copyChunk(chunk);
      committedChunks[chunk] = true;
    }
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
    return requireShape(values).persistentOwner();
  }

  private static PersistentLongList requireShape(List<Long> values) {
    return (PersistentLongList) copyOf(values);
  }

  private void checkIndex(int index) {
    if (index < 0 || index >= size) {
      throw new IndexOutOfBoundsException("Invalid persistent word index " + index);
    }
  }
}
