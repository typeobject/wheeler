package com.typeobject.wheeler.compiler.ast.quantum;

import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import java.util.List;

public final class QuantumFunction extends Node {
    private final List<Parameter> parameters;
    private final QuantumCircuit body;
    private final boolean isPure;
    private final boolean isReversible;

    public QuantumFunction(Position position, List<Annotation> annotations,
                           List<Parameter> parameters, QuantumCircuit body,
                           boolean isPure, boolean isReversible) {
        super(position, annotations);
        this.parameters = parameters;
        this.body = body;
        this.isPure = isPure;
        this.isReversible = isReversible;
    }

    public List<Parameter> getParameters() {
        return parameters;
    }

    public QuantumCircuit getBody() {
        return body;
    }

    public boolean isPure() {
        return isPure;
    }

    public boolean isReversible() {
        return isReversible;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumFunction(this);
    }
}