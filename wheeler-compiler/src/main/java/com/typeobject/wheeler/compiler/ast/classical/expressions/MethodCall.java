package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import java.util.List;

public final class MethodCall extends ClassicalExpression {
    private final Expression receiver;
    private final String methodName;
    private final List<Expression> arguments;

    public MethodCall(Position position, List<Annotation> annotations,
                      Expression receiver, String methodName, List<Expression> arguments) {
        super(position, annotations);
        this.receiver = receiver;
        this.methodName = methodName;
        this.arguments = arguments;
    }

    public Expression getReceiver() {
        return receiver;
    }

    public String getMethodName() {
        return methodName;
    }

    public List<Expression> getArguments() {
        return arguments;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitMethodCall(this);
    }
}