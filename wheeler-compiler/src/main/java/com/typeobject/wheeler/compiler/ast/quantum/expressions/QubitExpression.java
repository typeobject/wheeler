package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public abstract class QubitExpression extends Expression {
    protected QubitExpression(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}