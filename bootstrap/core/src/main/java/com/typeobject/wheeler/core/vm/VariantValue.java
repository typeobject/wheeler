package com.typeobject.wheeler.core.vm;

import java.util.List;

/** Immutable runtime value for one verified nominal variant case. */
public record VariantValue(int typeId, int tag, List<Long> fields) {
  public VariantValue {
    if (typeId < 0 || tag < 0) {
      throw new IllegalArgumentException("Invalid variant identity");
    }
    fields = List.copyOf(fields);
  }
}
