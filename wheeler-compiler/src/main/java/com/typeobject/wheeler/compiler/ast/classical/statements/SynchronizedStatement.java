package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.classical.Block;

import java.util.List;

public final class SynchronizedStatement extends Statement {
    private final Expression lock;
    private final Block body;

    public SynchronizedStatement(Position position, List<Annotation> annotations,
                                 Expression lock, Block body) {
        super(position, annotations);
        this.lock = lock;
        this.body = body;
    }

    public Expression getLock() {
        return lock;
    }

    public Block getBody() {
        return body;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitSynchronizedStatement(this);
    }
}