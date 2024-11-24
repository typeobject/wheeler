package com.typeobject.wheeler.compiler.ast.classical.expressions;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;

public final class VariableReference extends ClassicalExpression {
    private final String name;

    public VariableReference(Position position, List<Annotation> annotations, String name) {
        super(position, annotations);
        this.name = name;
    }

    public String getName() {
        return name;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitVariableReference(this);
    }
}