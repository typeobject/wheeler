package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;

import java.util.List;

public final class QuantumArrayAccess extends QubitExpression {
    private final Expression array;
    private final Expression index;

    public QuantumArrayAccess(Position position, List<Annotation> annotations,
                              Expression array, Expression index) {
        super(position, annotations);
        this.array = array;
        this.index = index;
    }

    public Expression getArray() {
        return array;
    }

    public Expression getIndex() {
        return index;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumArrayAccess(this);
    }
}