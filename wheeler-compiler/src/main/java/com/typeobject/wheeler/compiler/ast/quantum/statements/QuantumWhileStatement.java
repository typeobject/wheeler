package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;

import java.util.List;

public final class QuantumWhileStatement extends QuantumStatement {
    private final QubitExpression condition;
    private final QuantumBlock body;
    private final Expression termination;

    public QuantumWhileStatement(Position position, List<Annotation> annotations,
                                 QubitExpression condition, QuantumBlock body,
                                 Expression termination) {
        super(position, annotations);
        this.condition = condition;
        this.body = body;
        this.termination = termination;
    }

    public QubitExpression getCondition() {
        return condition;
    }

    public QuantumBlock getBody() {
        return body;
    }

    public Expression getTermination() {
        return termination;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumWhileStatement(this);
    }
}