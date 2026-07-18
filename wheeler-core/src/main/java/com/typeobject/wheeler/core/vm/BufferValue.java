package com.typeobject.wheeler.core.vm;

import java.util.List;

/** Immutable snapshot of one region-owned signed-word buffer. */
public record BufferValue(
    int id, int regionId, BufferKind kind, List<Long> elements, boolean dropped) {
  public BufferValue {
    if (id < 0 || regionId < 0 || kind == null || (!dropped && elements.isEmpty())) {
      throw new IllegalArgumentException("Invalid buffer value");
    }
    elements = List.copyOf(elements);
  }
}
