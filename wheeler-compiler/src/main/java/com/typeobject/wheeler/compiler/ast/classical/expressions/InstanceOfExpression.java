package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Type;

public final class InstanceOfExpression extends ClassicalExpression {
    private final Expression expression;
    private final Type type;

    public InstanceOfExpression(Position position, List<Annotation> annotations,
                                Expression expression, Type type) {
        super(position, annotations);
        this.expression = expression;
        this.type = type;
    }

    public Expression getExpression() {
        return expression;
    }

    public Type getType() {
        return type;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitInstanceOf(this);
    }
}