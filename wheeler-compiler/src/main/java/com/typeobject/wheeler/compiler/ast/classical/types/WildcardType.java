package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class WildcardType extends ClassicalType {
    private final BoundKind boundKind;
    private final Type bound;

    public WildcardType(Position position, List<Annotation> annotations,
                        BoundKind boundKind, Type bound) {
        super(position, annotations, "?", List.of(), false);
        this.boundKind = boundKind;
        this.bound = bound;
    }

    public Type getBound() {
        return bound;
    }

    @Override
    public boolean isNumeric() {
        return false;
    }

    @Override
    public boolean isIntegral() {
        return false;
    }

    @Override
    public boolean isBoolean() {
        return false;
    }

    @Override
    public boolean isOrdered() {
        return false;
    }

    @Override
    public boolean isComparableTo(ClassicalType other) {
        return false;
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        return false;
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        return null;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitWildcardType(this);
    }

    public enum BoundKind {
        EXTENDS,
        SUPER,
        NONE
    }
}