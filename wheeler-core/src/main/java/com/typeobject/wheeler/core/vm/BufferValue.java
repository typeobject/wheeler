package com.typeobject.wheeler.core.vm;

import java.util.List;

/** Immutable snapshot of one region-owned signed-word buffer. */
public record BufferValue(
    int id,
    int regionId,
    BufferKind kind,
    int length,
    List<Long> elements,
    boolean dropped) {
  public BufferValue {
    if (id < 0 || regionId < 0 || kind == null || length <= 0
        || (!dropped && elements.size() != kind.storageSlots(length))
        || (dropped && !elements.isEmpty())) {
      throw new IllegalArgumentException("Invalid buffer value");
    }
    elements = List.copyOf(elements);
  }
}
