package com.typeobject.wheeler.compiler.ast.quantum.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public class QuantumType extends Type {
    private final QuantumTypeKind kind;
    private final int size;

    public QuantumType(Position position, List<Annotation> annotations, QuantumTypeKind kind) {
        this(position, annotations, kind, 1);
    }

    public QuantumType(Position position, List<Annotation> annotations, QuantumTypeKind kind, int size) {
        super(position, annotations);
        this.kind = kind;
        this.size = size;
    }

    public QuantumTypeKind getKind() {
        return kind;
    }

    public int getSize() {
        return size;
    }

    @Override
    public boolean isQuantum() {
        return true;
    }

    @Override
    public boolean isClassical() {
        return false;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumType(this);
    }

    @Override
    public String toString() {
        if (kind == QuantumTypeKind.QUREG) {
            return "qureg[" + size + "]";
        }
        return kind.toString().toLowerCase();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof QuantumType that)) return false;

        return size == that.size && kind == that.kind;
    }

    @Override
    public int hashCode() {
        int result = kind.hashCode();
        result = 31 * result + size;
        return result;
    }
}