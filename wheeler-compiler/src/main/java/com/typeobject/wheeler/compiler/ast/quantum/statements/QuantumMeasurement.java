package com.typeobject.wheeler.compiler.ast.quantum.statements;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;

public final class QuantumMeasurement extends QuantumStatement implements Measurable {
  private final QubitExpression target;
  private final String result;
  private final Type measurementType;

  public QuantumMeasurement(Position position, List<Annotation> annotations,
                            QubitExpression target, String result, Type measurementType) {
    super(position, annotations);
    this.target = target;
    this.result = result;
    this.measurementType = measurementType;
  }

  public QubitExpression getTarget() {
    return target;
  }

  public String getResult() {
    return result;
  }

  @Override
  public Type getMeasurementType() {
    return measurementType;
  }

  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitQuantumMeasurement(this);
  }
}