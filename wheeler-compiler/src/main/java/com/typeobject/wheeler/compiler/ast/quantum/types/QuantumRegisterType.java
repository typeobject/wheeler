package com.typeobject.wheeler.compiler.ast.quantum.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;

import java.util.List;

public final class QuantumRegisterType extends QuantumType {
    private final int size;

    public QuantumRegisterType(Position position, List<Annotation> annotations,
                               int size) {
        super(position, annotations, QuantumTypeKind.QUREG);
        this.size = size;
    }

    public int getSize() {
        return size;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumRegisterType(this);
    }
}