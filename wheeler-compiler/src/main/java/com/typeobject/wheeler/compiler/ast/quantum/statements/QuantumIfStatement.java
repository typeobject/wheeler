package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class QuantumIfStatement extends QuantumStatement {
  private final QubitExpression condition;
  private final QuantumBlock thenBlock;
  private final QuantumBlock elseBlock;

  public QuantumIfStatement(Position position, List<Annotation> annotations,
                            QubitExpression condition, QuantumBlock thenBlock,
                            QuantumBlock elseBlock) {
    super(position, annotations);
    this.condition = condition;
    this.thenBlock = thenBlock;
    this.elseBlock = elseBlock;
  }

  public QubitExpression getCondition() {
    return condition;
  }

  public QuantumBlock getThenBlock() {
    return thenBlock;
  }

  public QuantumBlock getElseBlock() {
    return elseBlock;
  }

  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitQuantumIfStatement(this);
  }
}