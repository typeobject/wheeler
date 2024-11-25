package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;

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
        // A type parameter is comparable if its bounds are comparable
        for (Type bound : bounds) {
            if (bound instanceof ClassicalType && ((ClassicalType) bound).isComparableTo(other)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        // A type parameter can be assigned from types that satisfy its bounds
        for (Type bound : bounds) {
            if (bound instanceof ClassicalType && !((ClassicalType) bound).isAssignableFrom(source)) {
                return false;
            }
        }
        return true;
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        if (isAssignableFrom(other)) return this;
        return null;
    }
}
