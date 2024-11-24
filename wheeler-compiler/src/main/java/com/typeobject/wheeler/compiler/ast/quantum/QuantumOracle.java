package com.typeobject.wheeler.compiler.ast.quantum;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public final class QuantumOracle extends Node {
    private final List<String> controls;
    private final List<String> targets;
    private final Expression function;

    public QuantumOracle(Position position, List<Annotation> annotations,
                         List<String> controls, List<String> targets,
                         Expression function) {
        super(position, annotations);
        this.controls = controls;
        this.targets = targets;
        this.function = function;
    }

    public List<String> getControls() {
        return controls;
    }

    public List<String> getTargets() {
        return targets;
    }

    public Expression getFunction() {
        return function;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumOracle(this);
    }
}