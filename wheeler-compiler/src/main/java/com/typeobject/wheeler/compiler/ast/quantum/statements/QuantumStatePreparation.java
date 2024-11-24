package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.StateExpression;

public final class QuantumStatePreparation extends QuantumStatement {
  private final QubitExpression target;
  private final StateExpression state;
}
