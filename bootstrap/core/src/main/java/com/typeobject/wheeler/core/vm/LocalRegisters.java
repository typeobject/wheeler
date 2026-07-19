package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/** Persistent chunked local-register storage shared by immutable control frames. */
final class LocalRegisters {
  private static final int CHUNK_SIZE = 32;

  private final int size;
  private final long[][] chunks;

  private LocalRegisters(int size, long[][] chunks) {
    this.size = size;
    this.chunks = chunks;
  }

  static LocalRegisters create(int size, List<Long> arguments) {
    if (size < 0 || arguments.size() > size) {
      throw new IllegalArgumentException("Invalid local register signature");
    }
    long[][] chunks = new long[(size + CHUNK_SIZE - 1) / CHUNK_SIZE][];
    for (int chunk = 0; chunk < chunks.length; chunk++) {
      chunks[chunk] = new long[Math.min(CHUNK_SIZE, size - chunk * CHUNK_SIZE)];
    }
    for (int index = 0; index < arguments.size(); index++) {
      chunks[index / CHUNK_SIZE][index % CHUNK_SIZE] = arguments.get(index);
    }
    return new LocalRegisters(size, chunks);
  }

  int size() {
    return size;
  }

  long get(int index) {
    checkIndex(index);
    return chunks[index / CHUNK_SIZE][index % CHUNK_SIZE];
  }

  LocalRegisters with(int index, long value) {
    checkIndex(index);
    int chunk = index / CHUNK_SIZE;
    long[][] updated = chunks.clone();
    updated[chunk] = chunks[chunk].clone();
    updated[chunk][index % CHUNK_SIZE] = value;
    return new LocalRegisters(size, updated);
  }

  List<Long> asList() {
    List<Long> result = new ArrayList<>(size);
    for (int index = 0; index < size; index++) {
      result.add(get(index));
    }
    return List.copyOf(result);
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    if (!(other instanceof LocalRegisters registers) || size != registers.size) {
      return false;
    }
    return Arrays.deepEquals(chunks, registers.chunks);
  }

  @Override
  public int hashCode() {
    return 31 * size + Arrays.deepHashCode(chunks);
  }

  private void checkIndex(int index) {
    if (index < 0 || index >= size) {
      throw new IndexOutOfBoundsException("Invalid local register " + index);
    }
  }
}
