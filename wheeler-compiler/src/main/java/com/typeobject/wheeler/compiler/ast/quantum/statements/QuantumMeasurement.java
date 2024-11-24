package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;

public final class QuantumMeasurement extends QuantumStatement implements Measurable {
  private final QubitExpression target;
  private final Expression resultVariable;

  @Override
  public Type getMeasurementType() {
    return target.getType();
  }
}
