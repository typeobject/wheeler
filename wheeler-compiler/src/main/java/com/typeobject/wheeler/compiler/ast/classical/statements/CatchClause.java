package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.Block;

import java.util.List;

public final class CatchClause extends Statement {
    private final Type exceptionType;
    private final String parameter;
    private final Block body;

    public CatchClause(Position position, List<Annotation> annotations,
                       Type exceptionType, String parameter, Block body) {
        super(position, annotations);
        this.exceptionType = exceptionType;
        this.parameter = parameter;
        this.body = body;
    }

    public Type getExceptionType() {
        return exceptionType;
    }

    public String getParameter() {
        return parameter;
    }

    public Block getBody() {
        return body;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitCatchClause(this);
    }
}