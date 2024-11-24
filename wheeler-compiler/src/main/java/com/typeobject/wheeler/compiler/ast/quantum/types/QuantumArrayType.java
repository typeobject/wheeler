package com.typeobject.wheeler.compiler.ast.quantum.types;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.List;

public final class QuantumArrayType extends QuantumType {
    private final Type elementType;
    private final int dimensions;

    public QuantumArrayType(Position position, List<Annotation> annotations,
                            Type elementType, int dimensions) {
        super(position, annotations, QuantumTypeKind.QUREG);
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
        return visitor.visitQuantumArrayType(this);
    }
}