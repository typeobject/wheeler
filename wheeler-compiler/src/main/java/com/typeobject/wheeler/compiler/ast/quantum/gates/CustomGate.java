package com.typeobject.wheeler.compiler.ast.quantum.gates;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;

public final class CustomGate extends QuantumGate {
    private final String name;
    private final List<Double> parameters;
    private final int numQubits;

    public CustomGate(String name, List<Double> parameters, int numQubits) {
        super(GateType.CUSTOM, numQubits);
        this.name = name;
        this.parameters = parameters;
        this.numQubits = numQubits;
    }

    public String getName() {
        return name;
    }

    public List<Double> getParameters() {
        return parameters;
    }

    @Override
    public void validate(List<QubitExpression> targets) {
        if (targets.size() != numQubits) {
            throw new IllegalArgumentException(
                    "Custom gate " + name + " requires " + numQubits +
                            " qubits but got " + targets.size());
        }
    }

    @Override
    public String toQASM() {
        StringBuilder sb = new StringBuilder(name);
        if (!parameters.isEmpty()) {
            sb.append("(");
            for (int i = 0; i < parameters.size(); i++) {
                if (i > 0) sb.append(",");
                sb.append(parameters.get(i));
            }
            sb.append(")");
        }
        return sb.toString();
    }
}