package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;

import java.util.List;

public final class ArrayInitializer extends ClassicalExpression {
    private final List<Expression> elements;

    public ArrayInitializer(Position position, List<Annotation> annotations,
                            List<Expression> elements) {
        super(position, annotations);
        this.elements = elements;
    }

    public List<Expression> getElements() {
        return elements;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitArrayInitializer(this);
    }
}