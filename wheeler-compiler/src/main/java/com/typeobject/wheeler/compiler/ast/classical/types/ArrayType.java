package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
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
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitArrayType(this);
    }
}