package com.typeobject.wheeler.core.bytecode;

import java.util.List;
import java.util.Objects;

/** A function, typed register signature, and optional validated inverse body. */
public record FunctionBody(
    int id,
    String name,
    boolean coherent,
    int parameterCount,
    List<ValueType> localTypes,
    boolean returnsValue,
    List<Instruction> forward,
    List<Instruction> inverse) {
  public FunctionBody {
    localTypes = List.copyOf(localTypes);
    if (id < 0
        || parameterCount < 0
        || localTypes.size() < parameterCount
        || localTypes.size() > 65_535) {
      throw new IllegalArgumentException("Function ID or frame signature is invalid");
    }
    for (int index = 0; index < parameterCount; index++) {
      if (localTypes.get(index) != ValueType.SIGNED) {
        throw new IllegalArgumentException("Bootstrap parameters must be signed registers");
      }
    }
    Objects.requireNonNull(name, "name");
    forward = List.copyOf(forward);
    inverse = List.copyOf(inverse);
  }


  public int localCount() {
    return localTypes.size();
  }

  public ValueType localType(int index) {
    return localTypes.get(index);
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
