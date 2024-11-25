package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class QuantumBarrier extends QuantumStatement {
    private final List<QubitExpression> qubits;

    public QuantumBarrier(Position position, List<Annotation> annotations,
                          List<QubitExpression> qubits) {
        super(position, annotations);
        this.qubits = qubits;
    }

    public List<QubitExpression> getQubits() {
        return qubits;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumBarrier(this);
    }
}