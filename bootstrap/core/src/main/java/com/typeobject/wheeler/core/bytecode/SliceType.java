package com.typeobject.wheeler.core.bytecode;

import java.util.Objects;

/** Canonical nonescaping immutable slice type descriptor. */
public record SliceType(int id, ValueType elementType) {
  public SliceType {
    if (id < 0 || id > 0x0fff_ffff) {
      throw new IllegalArgumentException("Invalid slice descriptor");
    }
    Objects.requireNonNull(elementType, "elementType");
  }
}
