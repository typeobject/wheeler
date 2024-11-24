package com.typeobject.wheeler.compiler.ast.classical.expressions;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;

public final class LiteralExpression extends ClassicalExpression {
    private final Object value;
    private final LiteralType literalType;

    public LiteralExpression(Position position, List<Annotation> annotations,
                             Object value, LiteralType literalType) {
        super(position, annotations);
        this.value = value;
        this.literalType = literalType;
    }

    public Object getValue() {
        return value;
    }

    public LiteralType getLiteralType() {
        return literalType;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitLiteralExpression(this);
    }
}