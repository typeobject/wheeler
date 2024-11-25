package com.typeobject.wheeler.compiler.ast.quantum;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class QuantumTeleport extends Node {
    private final QubitExpression source;
    private final QubitExpression target;
    private final List<QubitExpression> ancilla;

    public QuantumTeleport(Position position, List<Annotation> annotations,
                           QubitExpression source, QubitExpression target,
                           List<QubitExpression> ancilla) {
        super(position, annotations);
        this.source = source;
        this.target = target;
        this.ancilla = ancilla;
    }

    public QubitExpression getSource() {
        return source;
    }

    public QubitExpression getTarget() {
        return target;
    }

    public List<QubitExpression> getAncilla() {
        return ancilla;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumTeleport(this);
    }
}