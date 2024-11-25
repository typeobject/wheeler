package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.StateExpression;

import java.util.List;

public final class QuantumStatePreparation extends QuantumStatement {
    private final QubitExpression target;
    private final StateExpression state;

    public QuantumStatePreparation(Position position, List<Annotation> annotations,
                                   QubitExpression target, StateExpression state) {
        super(position, annotations);
        this.target = target;
        this.state = state;
    }

    public QubitExpression getTarget() {
        return target;
    }

    public StateExpression getState() {
        return state;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumStatePreparation(this);
    }
}