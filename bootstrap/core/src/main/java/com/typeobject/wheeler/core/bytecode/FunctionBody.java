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
    boolean implicitResultSlot,
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
    if (implicitResultSlot
        && (resultType == null || inverse.isEmpty() || localTypes.size() < 2
            || !localTypes.get(localTypes.size() - 2).equals(ValueType.BOOLEAN)
            || !localTypes.getLast().equals(resultType))) {
      throw new IllegalArgumentException("Implicit result slot signature is invalid");
    }
  }

  public FunctionBody(
      int id,
      String name,
      boolean coherent,
      int parameterCount,
      List<ValueType> localTypes,
      ValueType resultType,
      List<Instruction> forward,
      List<Instruction> inverse) {
    this(
        id, name, coherent, parameterCount, localTypes, resultType, false, forward, inverse);
  }

  public boolean returnsValue() {
    return resultType != null;
  }

  public int localCount() {
    return localTypes.size();
  }

  public int resultSlotBase() {
    if (!implicitResultSlot) {
      throw new IllegalStateException("Function has no implicit result slot: " + name);
    }
    return localTypes.size() - 2;
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
