package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;

import java.util.List;

public final class ForStatement extends Statement {
    private final Statement initialization;
    private final Expression condition;
    private final Statement update;
    private final Statement body;

    public ForStatement(Position position, List<Annotation> annotations,
                        Statement initialization, Expression condition,
                        Statement update, Statement body) {
        super(position, annotations);
        this.initialization = initialization;
        this.condition = condition;
        this.update = update;
        this.body = body;
    }

    public Statement getInitialization() {
        return initialization;
    }

    public Expression getCondition() {
        return condition;
    }

    public Statement getUpdate() {
        return update;
    }

    public Statement getBody() {
        return body;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitForStatement(this);
    }
}