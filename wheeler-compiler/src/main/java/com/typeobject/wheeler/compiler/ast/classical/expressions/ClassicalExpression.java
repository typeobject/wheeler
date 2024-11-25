package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public abstract class ClassicalExpression extends Expression {
    protected ClassicalExpression(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}