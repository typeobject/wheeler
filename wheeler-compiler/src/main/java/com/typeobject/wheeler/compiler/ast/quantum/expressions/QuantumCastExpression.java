package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;
import java.util.List;

public final class QuantumCastExpression extends QubitExpression {
    private final QuantumType targetType;
    private final Expression expression;

    public QuantumCastExpression(Position position, List<Annotation> annotations,
                                 QuantumType targetType, Expression expression) {
        super(position, annotations);
        this.targetType = targetType;
        this.expression = expression;
    }

    public QuantumType getTargetType() {
        return targetType;
    }

    public Expression getExpression() {
        return expression;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumCastExpression(this);
    }
}