package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.declarations.ClassDeclaration;
import java.util.List;

public final class ObjectCreationExpression extends ClassicalExpression {
    private final Type type;
    private final List<Expression> arguments;
    private final ClassDeclaration anonymousClass;

    public ObjectCreationExpression(Position position, List<Annotation> annotations,
                                    Type type, List<Expression> arguments,
                                    ClassDeclaration anonymousClass) {
        super(position, annotations);
        this.type = type;
        this.arguments = arguments;
        this.anonymousClass = anonymousClass;
    }

    public Type getType() {
        return type;
    }

    public List<Expression> getArguments() {
        return arguments;
    }

    public ClassDeclaration getAnonymousClass() {
        return anonymousClass;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitObjectCreation(this);
    }
}