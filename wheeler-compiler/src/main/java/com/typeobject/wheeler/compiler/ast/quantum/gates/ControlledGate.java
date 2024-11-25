package com.typeobject.wheeler.compiler.ast.quantum.gates;

import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class ControlledGate extends QuantumGate {
    private final QuantumGate base;
    private final int numControls;

    public ControlledGate(GateType type, QuantumGate base, int numControls) {
        super(type, base.getNumQubits() + numControls);
        this.base = base;
        this.numControls = numControls;
    }

    public QuantumGate getBase() {
        return base;
    }

    public int getNumControls() {
        return numControls;
    }

    @Override
    public void validate(List<QubitExpression> targets) {
        if (targets.size() != getNumQubits()) {
            throw new IllegalArgumentException(
                    "Controlled gate requires " + getNumQubits() +
                            " qubits but got " + targets.size());
        }
    }

    @Override
    public String toQASM() {
        return "c" + numControls + base.toQASM();
    }
}