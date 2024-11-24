package com.typeobject.wheeler.compiler.ast.classical.expressions;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class UnaryExpression extends ClassicalExpression {
    private final Expression operand;
    private final UnaryOperator operator;
    private final boolean prefix;

    public UnaryExpression(Position position, List<Annotation> annotations,
                           Expression operand, UnaryOperator operator, boolean prefix) {
        super(position, annotations);
        this.operand = operand;
        this.operator = operator;
        this.prefix = prefix;
    }

    public Expression getOperand() {
        return operand;
    }

    public UnaryOperator getOperator() {
        return operator;
    }

    public boolean isPrefix() {
        return prefix;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitUnaryExpression(this);
    }
}
