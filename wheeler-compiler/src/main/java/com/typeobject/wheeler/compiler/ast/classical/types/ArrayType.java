package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class ArrayType extends ClassicalType {
    private final Type elementType;
    private final int dimensions;

    public ArrayType(Position position, List<Annotation> annotations,
                     Type elementType, int dimensions) {
        super(position, annotations, elementType.toString() + "[]".repeat(dimensions),
                List.of(), false);
        this.elementType = elementType;
        this.dimensions = dimensions;
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
        if (!(other instanceof ArrayType)) return false;
        ArrayType otherArray = (ArrayType) other;
        if (dimensions != otherArray.dimensions) return false;
        if (!(elementType instanceof ClassicalType)) return false;
        return ((ClassicalType) elementType).isComparableTo((ClassicalType) otherArray.elementType);
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        if (!(source instanceof ArrayType)) return false;
        ArrayType sourceArray = (ArrayType) source;
        if (dimensions != sourceArray.dimensions) return false;
        if (!(elementType instanceof ClassicalType)) return false;
        return ((ClassicalType) elementType).isAssignableFrom((ClassicalType) sourceArray.elementType);
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        if (equals(other)) return this;
        return null;
    }
}