package com.typeobject.wheeler.compiler.ast.quantum.declarations;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class Parameter extends Declaration {
    private final Type type;
    private final boolean isReversible;

    public Parameter(Position position, List<Annotation> annotations,
                     Type type, String name, boolean isReversible) {
        super(position, annotations, List.of(), name);
        this.type = type;
        this.isReversible = isReversible;
    }

    public Type getType() {
        return type;
    }

    public boolean isReversible() {
        return isReversible;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitParameter(this);
    }
}