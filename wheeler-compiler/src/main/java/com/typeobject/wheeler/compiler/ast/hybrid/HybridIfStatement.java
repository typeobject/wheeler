package com.typeobject.wheeler.compiler.ast.hybrid;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;

import java.util.List;

public final class HybridIfStatement extends HybridStatement {
    private final Expression condition;
    private final HybridBlock thenBlock;
    private final HybridBlock elseBlock;

    public HybridIfStatement(Position position, List<Annotation> annotations,
                             Expression condition, HybridBlock thenBlock, HybridBlock elseBlock) {
        super(position, annotations);
        this.condition = condition;
        this.thenBlock = thenBlock;
        this.elseBlock = elseBlock;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitHybridIfStatement(this);
    }
}