// StandardGate.java
package com.typeobject.wheeler.compiler.ast.quantum.gates;

import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;

import java.util.List;

public final class StandardGate extends QuantumGate {
    public StandardGate(GateType type, int numQubits) {
        super(type, numQubits);
    }

    @Override
    public void validate(List<QubitExpression> targets) {
        if (targets.size() != getNumQubits()) {
            throw new IllegalArgumentException(
                    "Gate " + getType() + " requires " + getNumQubits() +
                            " qubits but got " + targets.size());
        }
    }

    @Override
    public String toQASM() {
        return getType().toString().toLowerCase();
    }
}
