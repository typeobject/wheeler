package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class QubitReference extends QubitExpression {
  private final String identifier;
  private final Expression index; // For accessing qureg
}
