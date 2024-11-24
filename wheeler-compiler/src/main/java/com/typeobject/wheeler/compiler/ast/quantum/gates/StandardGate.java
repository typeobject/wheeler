package com.typeobject.wheeler.compiler.ast.quantum.gates;

public final class StandardGate extends QuantumGate {
  private final GateType type;
  private final boolean isParameterized;

  @Override
  public int getArity() {
    return type.arity;
  }
}
