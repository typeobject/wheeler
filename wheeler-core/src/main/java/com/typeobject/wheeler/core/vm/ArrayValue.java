package com.typeobject.wheeler.core.vm;

import java.util.List;

/** Immutable runtime value for one verified fixed array. */
public record ArrayValue(int typeId, List<Long> elements) {
  public ArrayValue {
    if (typeId < 0 || elements.isEmpty()) {
      throw new IllegalArgumentException("Invalid array value");
    }
    elements = List.copyOf(elements);
  }
}
