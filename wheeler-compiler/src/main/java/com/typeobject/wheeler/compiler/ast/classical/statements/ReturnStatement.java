package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;

import java.util.List;

public final class ReturnStatement extends Statement {
    private final Expression value;

    public ReturnStatement(Position position, List<Annotation> annotations, Expression value) {
        super(position, annotations);
        this.value = value;
    }

    public Expression getValue() {
        return value;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitReturnStatement(this);
    }
}