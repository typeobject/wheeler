package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.QubitExpression;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;

public final class QuantumWhileStatement extends QuantumStatement {
  private final QubitExpression condition;
  private final QuantumBlock body;
  private final Expression termination;
}
