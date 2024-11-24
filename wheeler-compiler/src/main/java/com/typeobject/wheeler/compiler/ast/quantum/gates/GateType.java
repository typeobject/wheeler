package com.typeobject.wheeler.compiler.ast.quantum.gates;

public enum GateType {
  HADAMARD(1),
  PAULIX(1),
  PAULIY(1),
  PAULIZ(1),
  CNOT(2),
  TOFFOLI(3),
  PHASE(1),
  ROTATE(1);

  public final int arity;

  GateType(int arity) {
    this.arity = arity;
  }
}
