package com.typeobject.wheeler.compiler.ast.quantum.gates;

public abstract sealed class QuantumGate permits StandardGate, CustomGate {

  private final String name;
  private final int arity;
  private final boolean isParameterized;

  protected QuantumGate(String name, int arity, boolean isParameterized) {
    this.name = name;
    this.arity = arity;
    this.isParameterized = isParameterized;
  }

  public abstract void validate(List<QubitExpression> targets);

  public abstract String toQASM();
}
