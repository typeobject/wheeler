package com.typeobject.wheeler.compiler.ast.memory;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class CleanBlock extends Statement {
  private final List<QubitExpression> qubits;

  public CleanBlock(Position position, List<Annotation> annotations,
                    List<QubitExpression> qubits) {
    super(position, annotations);
    this.qubits = qubits;
  }

  public List<QubitExpression> getQubits() {
    return qubits;
  }

  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitCleanBlock(this);
  }
}