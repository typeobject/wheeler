package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.QuantumStatement;
import com.typeobject.wheeler.compiler.ast.QubitExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;

// Control flow
public final class QuantumIfStatement extends QuantumStatement {
  private final QubitExpression condition;
  private final QuantumBlock thenBlock;
  private final QuantumBlock elseBlock;
}
