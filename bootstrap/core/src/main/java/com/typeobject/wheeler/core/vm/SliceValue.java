package com.typeobject.wheeler.core.vm;

/** Immutable nonescaping view into one fixed-array value. */
public record SliceValue(int typeId, long arrayHandle, int start, int length) {
  public SliceValue {
    if (typeId < 0 || arrayHandle <= 0 || start < 0 || length < 0) {
      throw new IllegalArgumentException("Invalid slice value");
    }
  }
}
