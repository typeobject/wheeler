package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.List;

public final class MethodReferenceExpression extends ClassicalExpression {
    private final Expression qualifier;
    private final String methodName;
    private final List<Type> typeArguments;

    public MethodReferenceExpression(Position position, List<Annotation> annotations,
                                     Expression qualifier, String methodName,
                                     List<Type> typeArguments) {
        super(position, annotations);
        this.qualifier = qualifier;
        this.methodName = methodName;
        this.typeArguments = typeArguments;
    }

    public Expression getQualifier() {
        return qualifier;
    }

    public String getMethodName() {
        return methodName;
    }

    public List<Type> getTypeArguments() {
        return typeArguments;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitMethodReference(this);
    }
}