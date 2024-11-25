package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class InstanceOfExpression extends Expression {
    private final Expression expression;
    private final Type type;

    public InstanceOfExpression(Position position, List<Annotation> annotations,
                                Expression expression, Type type) {
        super(position, annotations);
        this.expression = expression;
        this.type = type;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitInstanceOf(this);
    }
}