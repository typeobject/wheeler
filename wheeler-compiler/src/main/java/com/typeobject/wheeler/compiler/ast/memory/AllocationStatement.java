package com.typeobject.wheeler.compiler.ast.memory;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;

import java.util.List;

public final class AllocationStatement extends Statement {
    private final Expression target;
    private final Expression size;

    public AllocationStatement(Position position, List<Annotation> annotations,
                               Expression target, Expression size) {
        super(position, annotations);
        this.target = target;
        this.size = size;
    }

    public Expression getTarget() {
        return target;
    }

    public Expression getSize() {
        return size;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitAllocationStatement(this);
    }
}