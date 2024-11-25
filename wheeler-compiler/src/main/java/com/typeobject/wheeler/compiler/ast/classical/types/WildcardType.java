package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class WildcardType extends ClassicalType {
    private final BoundKind boundKind;
    private final Type bound;

    public enum BoundKind {
        NONE,
        EXTENDS,
        SUPER
    }

    public WildcardType(Position position, List<Annotation> annotations,
                        BoundKind boundKind, Type bound) {
        super(position, annotations, "?", List.of(), false);
        this.boundKind = boundKind;
        this.bound = bound;
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
        if (boundKind == BoundKind.NONE) return true;
        if (!(bound instanceof ClassicalType)) return false;
        return boundKind == BoundKind.EXTENDS ?
                ((ClassicalType) bound).isComparableTo(other) :
                other.isComparableTo((ClassicalType) bound);
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        if (boundKind == BoundKind.NONE) return true;
        if (!(bound instanceof ClassicalType)) return false;
        return boundKind == BoundKind.EXTENDS ?
                ((ClassicalType) bound).isAssignableFrom(source) :
                source.isAssignableFrom((ClassicalType) bound);
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        if (isAssignableFrom(other)) return this;
        return null;
    }
}