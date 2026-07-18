package com.typeobject.wheeler.core.bytecode;

import java.util.Objects;

/** Canonical fixed-length immutable array type descriptor. */
public record ArrayType(int id, ValueType elementType, int length) {
  public ArrayType {
    if (id < 0 || id > 0x0fff_ffff || length <= 0 || length > 65_535) {
      throw new IllegalArgumentException("Invalid fixed array descriptor");
    }
    Objects.requireNonNull(elementType, "elementType");
  }
}
