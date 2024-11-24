package com.typeobject.wheeler.compiler.ast.classical.expressions;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public abstract sealed class ClassicalExpression extends Expression
        permits BinaryExpression, UnaryExpression, LiteralExpression,
        VariableReference, MethodCall, ArrayAccess, Assignment {

    protected ClassicalExpression(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}