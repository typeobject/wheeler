package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;

import java.util.List;

public final class TernaryExpression extends ClassicalExpression {
    private final Expression condition;
    private final Expression thenExpression;
    private final Expression elseExpression;

    public TernaryExpression(Position position, List<Annotation> annotations,
                             Expression condition, Expression thenExpression,
                             Expression elseExpression) {
        super(position, annotations);
        this.condition = condition;
        this.thenExpression = thenExpression;
        this.elseExpression = elseExpression;
    }

    public Expression getCondition() {
        return condition;
    }

    public Expression getThenExpression() {
        return thenExpression;
    }

    public Expression getElseExpression() {
        return elseExpression;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitTernary(this);
    }
}