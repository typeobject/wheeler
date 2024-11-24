package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import java.util.List;

public final class LambdaExpression extends ClassicalExpression {
    private final List<Parameter> parameters;
    private final Expression body;
    private final boolean isExpressionBody;

    public LambdaExpression(Position position, List<Annotation> annotations,
                            List<Parameter> parameters, Expression body,
                            boolean isExpressionBody) {
        super(position, annotations);
        this.parameters = parameters;
        this.body = body;
        this.isExpressionBody = isExpressionBody;
    }

    public List<Parameter> getParameters() {
        return parameters;
    }

    public Expression getBody() {
        return body;
    }

    public boolean isExpressionBody() {
        return isExpressionBody;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitLambda(this);
    }
}