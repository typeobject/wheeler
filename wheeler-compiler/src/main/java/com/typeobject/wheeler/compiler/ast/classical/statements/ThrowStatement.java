package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Expression;

import java.util.List;

public final class ThrowStatement extends Statement {
    private final Expression exception;

    public ThrowStatement(Position position, List<Annotation> annotations,
                          Expression exception) {
        super(position, annotations);
        this.exception = exception;
    }

    public Expression getException() {
        return exception;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitThrowStatement(this);
    }
}