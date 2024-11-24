package com.typeobject.wheeler.compiler.ast.quantum.declarations;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public final class QuantumAncillaDeclaration extends Declaration {
    private final Expression size;
    private final Expression initialState;

    public QuantumAncillaDeclaration(Position position, List<Annotation> annotations,
                                     String name, Expression size,
                                     Expression initialState) {
        super(position, annotations, List.of(), name);
        this.size = size;
        this.initialState = initialState;
    }

    public Expression getSize() {
        return size;
    }

    public Expression getInitialState() {
        return initialState;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumAncillaDeclaration(this);
    }
}