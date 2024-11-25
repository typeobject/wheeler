package com.typeobject.wheeler.compiler.ast.quantum.declarations;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;
import java.util.List;

public final class QuantumRegisterDeclaration extends Declaration {
    private final QuantumType type;
    private final Expression size;
    private final Expression initializer;

    public QuantumRegisterDeclaration(Position position, List<Annotation> annotations,
                                      QuantumType type, String name, Expression size,
                                      Expression initializer) {
        super(position, annotations, List.of(), name);
        this.type = type;
        this.size = size;
        this.initializer = initializer;
    }

    public QuantumType getType() {
        return type;
    }

    public Expression getSize() {
        return size;
    }

    public Expression getInitializer() {
        return initializer;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumRegisterDeclaration(this);
    }
}