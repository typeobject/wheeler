// QuantumType.java
package com.typeobject.wheeler.compiler.ast.quantum.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public class QuantumType extends Type {
    private final QuantumTypeKind kind;

    public QuantumType(Position position, List<Annotation> annotations, QuantumTypeKind kind) {
        super(position, annotations);
        this.kind = kind;
    }

    public QuantumTypeKind getKind() {
        return kind;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumType(this);
    }
}