package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.List;

public final class ArrayCreationExpression extends ClassicalExpression {
    private final Type elementType;
    private final List<Expression> dimensions;
    private final ArrayInitializer initializer;

    public ArrayCreationExpression(Position position, List<Annotation> annotations,
                                   Type elementType, List<Expression> dimensions,
                                   ArrayInitializer initializer) {
        super(position, annotations);
        this.elementType = elementType;
        this.dimensions = dimensions;
        this.initializer = initializer;
    }

    public Type getElementType() {
        return elementType;
    }

    public List<Expression> getDimensions() {
        return dimensions;
    }

    public ArrayInitializer getInitializer() {
        return initializer;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitArrayCreation(this);
    }
}