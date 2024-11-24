// QubitExpression.java
package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public abstract sealed class QubitExpression extends Expression
        permits QubitReference, TensorProduct {

  protected QubitExpression(Position position, List<Annotation> annotations) {
    super(position, annotations);
  }
}