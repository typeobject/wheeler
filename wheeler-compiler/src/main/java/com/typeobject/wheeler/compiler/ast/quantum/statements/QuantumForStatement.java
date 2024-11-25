package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public final class QuantumForStatement extends QuantumStatement {
    private final Expression initialization;
    private final Expression condition;
    private final Expression update;
    private final QuantumBlock body;

    public QuantumForStatement(Position position, List<Annotation> annotations,
                               Expression initialization, Expression condition,
                               Expression update, QuantumBlock body) {
        super(position, annotations);
        this.initialization = initialization;
        this.condition = condition;
        this.update = update;
        this.body = body;
    }

    public Expression getInitialization() {
        return initialization;
    }

    public Expression getCondition() {
        return condition;
    }

    public Expression getUpdate() {
        return update;
    }

    public QuantumBlock getBody() {
        return body;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumForStatement(this);
    }
}