package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;

public abstract sealed class QubitExpression extends Expression {
  public abstract QuantumType getType();
}
