package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import java.util.List;

public final class TypeParameter extends ClassicalType {
    private final String name;
    private final List<Type> bounds;

    public TypeParameter(Position position, List<Annotation> annotations,
                         String name, List<Type> bounds) {
        super(position, annotations, name, List.of(), false);
        this.name = name;
        this.bounds = bounds;
    }

    public String getName() {
        return name;
    }

    public List<Type> getBounds() {
        return bounds;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitTypeParameter(this);
    }
}