package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;

public final class TensorProduct extends QubitExpression {
  private final QubitExpression left;
  private final QubitExpression right;

  @Override
  public QuantumType getType() {
    // Compute combined type
    return null; // Implementation here
  }
}
