package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import java.util.List;

public final class ExpressionStatement extends Statement {
    private final Expression expression;

    public ExpressionStatement(Position position, List<Annotation> annotations,
                               Expression expression) {
        super(position, annotations);
        this.expression = expression;
    }

    public Expression getExpression() {
        return expression;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitExpressionStatement(this);
    }
}