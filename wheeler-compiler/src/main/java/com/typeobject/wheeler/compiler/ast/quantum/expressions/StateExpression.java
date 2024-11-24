package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public final class StateExpression extends Expression {
  private final List<ComplexNumber> coefficients;
  private final List<QubitExpression> basis;
}
