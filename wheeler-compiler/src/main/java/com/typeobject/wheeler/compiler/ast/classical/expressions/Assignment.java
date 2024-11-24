package com.typeobject.wheeler.compiler.ast.classical.expressions;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class Assignment extends ClassicalExpression {
    private final Expression target;
    private final Expression value;
    private final AssignmentOperator operator;

    public Assignment(Position position, List<Annotation> annotations,
                      Expression target, Expression value, AssignmentOperator operator) {
        super(position, annotations);
        this.target = target;
        this.value = value;
        this.operator = operator;
    }

    public Expression getTarget() {
        return target;
    }

    public Expression getValue() {
        return value;
    }

    public AssignmentOperator getOperator() {
        return operator;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitAssignment(this);
    }
}