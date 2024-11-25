// QubitReference.java
package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;

import java.util.List;

public final class QubitReference extends QubitExpression {
    private final String identifier;

    public QubitReference(Position position, List<Annotation> annotations, String identifier) {
        super(position, annotations);
        this.identifier = identifier;
    }

    public String getIdentifier() {
        return identifier;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQubitReference(this);
    }
}