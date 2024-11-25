package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import com.typeobject.wheeler.compiler.ast.quantum.gates.QuantumGate;

import java.util.ArrayList;
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

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumGateApplication(this);
    }

    public static class Builder {
        private final List<Annotation> annotations = new ArrayList<>();
        private final QuantumGate gate;
        private final List<QubitExpression> targets = new ArrayList<>();
        private Position position;

        public Builder(QuantumGate gate) {
            this.gate = gate;
        }

        public Builder position(Position position) {
            this.position = position;
            return this;
        }

        public Builder addTarget(QubitExpression target) {
            this.targets.add(target);
            return this;
        }

        public Builder addAnnotation(Annotation annotation) {
            this.annotations.add(annotation);
            return this;
        }

        public QuantumGateApplication build() {
            return new QuantumGateApplication(position, annotations, gate, targets);
        }
    }
}