package com.typeobject.wheeler.compiler.ast.quantum.gates;

import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public abstract class QuantumGate {
    private final GateType type;
    private final int numQubits;

    protected QuantumGate(GateType type, int numQubits) {
        this.type = type;
        this.numQubits = numQubits;
    }

    public GateType getType() {
        return type;
    }

    public int getNumQubits() {
        return numQubits;
    }

    public abstract void validate(List<QubitExpression> targets);

    public abstract String toQASM();
}