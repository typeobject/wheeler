package com.typeobject.wheeler.compiler.ast.quantum;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class EntanglementOperation extends Node {
    private final List<QubitExpression> qubits;
    private final EntanglementType type;

    public enum EntanglementType {
        BELL_PAIR,
        GHZ_STATE,
        W_STATE,
        CLUSTER_STATE
    }

    public EntanglementOperation(Position position, List<Annotation> annotations,
                                 List<QubitExpression> qubits,
                                 EntanglementType type) {
        super(position, annotations);
        this.qubits = qubits;
        this.type = type;
    }

    public List<QubitExpression> getQubits() {
        return qubits;
    }

    public EntanglementType getType() {
        return type;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitEntanglementOperation(this);
    }
}