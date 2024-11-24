package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class WildcardType extends ClassicalType {
    public enum BoundKind {
        NONE,
        EXTENDS,
        SUPER
    }

    private final BoundKind boundKind;
    private final Type bound;

    public WildcardType(Position position, List<Annotation> annotations,
                        BoundKind boundKind, Type bound) {
        super(position, annotations, "?", List.of(), false);
        this.boundKind = boundKind;
        this.bound = bound;
    }

    public BoundKind getBoundKind() {
        return boundKind;
    }

    public Type getBound() {
        return bound;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitWildcardType(this);
    }
}
