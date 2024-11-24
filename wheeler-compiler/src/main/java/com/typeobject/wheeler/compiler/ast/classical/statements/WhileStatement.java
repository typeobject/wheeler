package com.typeobject.wheeler.compiler.ast.classical.statements;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class WhileStatement extends Statement {
    private final Expression condition;
    private final Statement body;

    public WhileStatement(Position position, List<Annotation> annotations,
                          Expression condition, Statement body) {
        super(position, annotations);
        this.condition = condition;
        this.body = body;
    }

    public Expression getCondition() {
        return condition;
    }

    public Statement getBody() {
        return body;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitWhileStatement(this);
    }
}