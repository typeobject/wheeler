package com.typeobject.wheeler.compiler.ast.memory;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.classical.Block;

import java.util.List;

public final class UncomputeBlock extends Statement {
    private final Block body;

    public UncomputeBlock(Position position, List<Annotation> annotations,
                          Block body) {
        super(position, annotations);
        this.body = body;
    }

    public Block getBody() {
        return body;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitUncomputeBlock(this);
    }
}