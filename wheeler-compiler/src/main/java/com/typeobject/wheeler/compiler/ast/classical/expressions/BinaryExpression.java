package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public final class BinaryExpression extends ClassicalExpression {
    private final Expression left;
    private final Expression right;
    private final BinaryOperator operator;

    public BinaryExpression(Position position, List<Annotation> annotations,
                            Expression left, Expression right, BinaryOperator operator) {
        super(position, annotations);
        this.left = left;
        this.right = right;
        this.operator = operator;
    }

    public Expression getLeft() {
        return left;
    }

    public Expression getRight() {
        return right;
    }

    public BinaryOperator getOperator() {
        return operator;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitBinaryExpression(this);
    }
}