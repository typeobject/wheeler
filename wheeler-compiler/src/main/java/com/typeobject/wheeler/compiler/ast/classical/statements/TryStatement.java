package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import java.util.List;

public final class TryStatement extends Statement {
    private final Block tryBlock;
    private final List<CatchClause> catchClauses;
    private final Block finallyBlock;

    public TryStatement(Position position, List<Annotation> annotations,
                        Block tryBlock, List<CatchClause> catchClauses,
                        Block finallyBlock) {
        super(position, annotations);
        this.tryBlock = tryBlock;
        this.catchClauses = catchClauses;
        this.finallyBlock = finallyBlock;
    }

    public Block getTryBlock() {
        return tryBlock;
    }

    public List<CatchClause> getCatchClauses() {
        return catchClauses;
    }

    public Block getFinallyBlock() {
        return finallyBlock;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitTryStatement(this);
    }
}