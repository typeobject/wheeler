package com.typeobject.wheeler.compiler.ast.memory;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import java.util.List;

public final class GarbageCollectionStatement extends Statement {
    private final boolean forceCollection;

    public GarbageCollectionStatement(Position position, List<Annotation> annotations,
                                      boolean forceCollection) {
        super(position, annotations);
        this.forceCollection = forceCollection;
    }

    public boolean isForceCollection() {
        return forceCollection;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitGarbageCollection(this);
    }
}