package com.typeobject.wheeler.compiler.ast.quantum;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumStatement;

import java.util.List;

public final class QuantumCircuit extends Node {
    private final List<String> parameters;
    private final List<QuantumStatement> statements;

    public QuantumCircuit(Position position, List<Annotation> annotations,
                          List<String> parameters,
                          List<QuantumStatement> statements) {
        super(position, annotations);
        this.parameters = parameters;
        this.statements = statements;
    }

    public List<String> getParameters() {
        return parameters;
    }

    public List<QuantumStatement> getStatements() {
        return statements;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumCircuit(this);
    }
}