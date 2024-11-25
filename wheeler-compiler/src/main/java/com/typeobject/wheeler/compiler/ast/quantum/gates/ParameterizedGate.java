package com.typeobject.wheeler.compiler.ast.quantum.gates;

import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class ParameterizedGate extends QuantumGate {
    private final List<Double> parameters;

    public ParameterizedGate(GateType type, int numQubits, List<Double> parameters) {
        super(type, numQubits);
        this.parameters = parameters;
    }

    public List<Double> getParameters() {
        return parameters;
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
        StringBuilder sb = new StringBuilder(getType().toString().toLowerCase());
        sb.append("(");
        for (int i = 0; i < parameters.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(parameters.get(i));
        }
        sb.append(")");
        return sb.toString();
    }
}