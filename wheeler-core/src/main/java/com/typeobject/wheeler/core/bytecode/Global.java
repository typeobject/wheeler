package com.typeobject.wheeler.core.bytecode;

import java.util.Objects;

/** A version-1 signed 64-bit global location. */
public record Global(String name, long initialValue) {
  public Global {
    Objects.requireNonNull(name, "name");
    if (!name.matches("[A-Za-z_][A-Za-z0-9_]*")) {
      throw new IllegalArgumentException("Invalid global name: " + name);
    }
  }
}
