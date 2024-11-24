package com.typeobject.wheeler.compiler.ast.classical.statements;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class DoWhileStatement extends Statement {
    private final Statement body;
    private final Expression condition;

    public DoWhileStatement(Position position, List<Annotation> annotations,
                            Statement body, Expression condition) {
        super(position, annotations);
        this.body = body;
        this.condition = condition;
    }

    public Statement getBody() {
        return body;
    }

    public Expression getCondition() {
        return condition;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitDoWhileStatement(this);
    }
}