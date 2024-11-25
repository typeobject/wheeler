package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import com.typeobject.wheeler.compiler.ast.quantum.gates.QuantumGate;

import java.util.List;

public final class QuantumGateApplication extends QuantumStatement {
    private final QuantumGate gate;
    private final List<QubitExpression> targets;

    public QuantumGateApplication(Position position, List<Annotation> annotations,
                                  QuantumGate gate, List<QubitExpression> targets) {
        super(position, annotations);
        this.gate = gate;
        this.targets = targets;
    }

    public QuantumGate getGate() {
        return gate;
    }

    public List<QubitExpression> getTargets() {
        return targets;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumGateApplication(this);
    }
}