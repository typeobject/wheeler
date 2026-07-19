package com.typeobject.wheeler.core.bytecode;

import java.util.Objects;

/** A signed 64-bit global location in Wheeler's first bytecode format. */
public record Global(String name, long initialValue) {
  public Global {
    Objects.requireNonNull(name, "name");
    if (!name.matches("[A-Za-z_][A-Za-z0-9_]*")) {
      throw new IllegalArgumentException("Invalid global name: " + name);
    }
  }
}
