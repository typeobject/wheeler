package com.typeobject.wheeler.compiler.ast.classical.statements;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class AssertStatement extends Statement {
    private final Expression condition;
    private final Expression message;

    public AssertStatement(Position position, List<Annotation> annotations,
                           Expression condition, Expression message) {
        super(position, annotations);
        this.condition = condition;
        this.message = message;
    }

    public Expression getCondition() {
        return condition;
    }

    public Expression getMessage() {
        return message;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitAssertStatement(this);
    }
}
