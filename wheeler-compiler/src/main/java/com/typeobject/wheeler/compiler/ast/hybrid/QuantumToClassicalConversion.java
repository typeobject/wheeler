package com.typeobject.wheeler.compiler.ast.hybrid;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class QuantumToClassicalConversion extends HybridStatement {
    private final QubitExpression quantum;
    private final Expression classical;

    public QuantumToClassicalConversion(Position position, List<Annotation> annotations,
                                        QubitExpression quantum, Expression classical) {
        super(position, annotations);
        this.quantum = quantum;
        this.classical = classical;
    }

    public QubitExpression getQuantum() {
        return quantum;
    }

    public Expression getClassical() {
        return classical;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumToClassical(this);
    }
}