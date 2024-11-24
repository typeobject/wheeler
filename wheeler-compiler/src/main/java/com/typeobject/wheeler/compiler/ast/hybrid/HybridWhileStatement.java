package com.typeobject.wheeler.compiler.ast.hybrid;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class HybridWhileStatement extends HybridStatement {
    private final Expression condition;
    private final HybridBlock body;
    private final Expression termination;

    public HybridWhileStatement(Position position, List<Annotation> annotations,
                                Expression condition, HybridBlock body, Expression termination) {
        super(position, annotations);
        this.condition = condition;
        this.body = body;
        this.termination = termination;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitHybridWhileStatement(this);
    }
}