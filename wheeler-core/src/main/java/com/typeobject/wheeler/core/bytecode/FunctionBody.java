package com.typeobject.wheeler.core.bytecode;

import java.util.List;
import java.util.Objects;

/** A function and its optional validated inverse body. */
public record FunctionBody(
    int id,
    String name,
    boolean coherent,
    int localCount,
    List<Instruction> forward,
    List<Instruction> inverse) {
  public FunctionBody {
    if (id < 0 || localCount < 0 || localCount > 65_535) {
      throw new IllegalArgumentException("Function ID or local count is invalid");
    }
    Objects.requireNonNull(name, "name");
    forward = List.copyOf(forward);
    inverse = List.copyOf(inverse);
  }

  public boolean reversible() {
    return !inverse.isEmpty();
  }

  public List<Instruction> body(boolean inverseDirection) {
    if (inverseDirection && inverse.isEmpty()) {
      throw new BytecodeException("Function has no inverse body: " + name);
    }
    return inverseDirection ? inverse : forward;
  }
}
