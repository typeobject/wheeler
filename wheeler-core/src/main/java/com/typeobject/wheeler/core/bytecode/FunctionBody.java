package com.typeobject.wheeler.core.bytecode;

import java.util.List;
import java.util.Objects;

/** A function with typed registers, a nullable void/result type, and an optional inverse body. */
public record FunctionBody(
    int id,
    String name,
    boolean coherent,
    int parameterCount,
    List<ValueType> localTypes,
    ValueType resultType,
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
    Objects.requireNonNull(name, "name");
    forward = List.copyOf(forward);
    inverse = List.copyOf(inverse);
  }



  public boolean returnsValue() {
    return resultType != null;
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
