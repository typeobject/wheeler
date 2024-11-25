package com.typeobject.wheeler.compiler.ast.quantum.gates;

import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class InverseGate extends QuantumGate {
    private final QuantumGate base;

    public InverseGate(QuantumGate base) {
        super(base.getType(), base.getNumQubits());
        this.base = base;
    }

    public QuantumGate getBase() {
        return base;
    }

    @Override
    public void validate(List<QubitExpression> targets) {
        base.validate(targets);
    }

    @Override
    public String toQASM() {
        return base.toQASM() + "†";
    }
}
