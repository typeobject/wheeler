package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
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

    public Type getElementType() {
        return elementType;
    }

    public int getDimensions() {
        return dimensions;
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
        if (!(other instanceof ArrayType otherArray)) return false;
        if (dimensions != otherArray.dimensions) return false;
        if (!(elementType instanceof ClassicalType)) return false;
        return ((ClassicalType) elementType).isComparableTo((ClassicalType) otherArray.elementType);
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        if (!(source instanceof ArrayType sourceArray)) return false;
        if (dimensions != sourceArray.dimensions) return false;
        if (!(elementType instanceof ClassicalType)) return false;
        return ((ClassicalType) elementType).isAssignableFrom((ClassicalType) sourceArray.elementType);
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        if (equals(other)) return this;
        return null;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitArrayType(this);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ArrayType arrayType)) return false;
        if (!super.equals(o)) return false;

        return dimensions == arrayType.dimensions &&
                elementType.equals(arrayType.elementType);
    }

    @Override
    public int hashCode() {
        int result = super.hashCode();
        result = 31 * result + elementType.hashCode();
        result = 31 * result + dimensions;
        return result;
    }
}