
// StateExpression.java
package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class StateExpression extends Expression {
  private final List<ComplexNumber> coefficients;
  private final int numQubits;

  public StateExpression(Position position, List<Annotation> annotations,
                         List<ComplexNumber> coefficients, int numQubits) {
    super(position, annotations);
    this.coefficients = coefficients;
    this.numQubits = numQubits;
  }

  public List<ComplexNumber> getCoefficients() {
    return coefficients;
  }

  public int getNumQubits() {
    return numQubits;
  }

  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitStateExpression(this);
  }
}