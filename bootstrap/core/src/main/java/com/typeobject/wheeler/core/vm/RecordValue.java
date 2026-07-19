package com.typeobject.wheeler.core.vm;

import java.util.List;

/** Immutable nominal record value stored in deterministic VM allocation order. */
public record RecordValue(int typeId, List<Long> fields) {
  public RecordValue {
    if (typeId < 0) {
      throw new IllegalArgumentException("Negative record type ID");
    }
    fields = List.copyOf(fields);
  }
}
