package com.typeobject.wheeler.compiler.ast.hybrid;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class ClassicalToQuantumConversion extends HybridStatement {
    private final Expression classical;
    private final QubitExpression quantum;

    public ClassicalToQuantumConversion(Position position, List<Annotation> annotations,
                                        Expression classical, QubitExpression quantum) {
        super(position, annotations);
        this.classical = classical;
        this.quantum = quantum;
    }

    public Expression getClassical() {
        return classical;
    }

    public QubitExpression getQuantum() {
        return quantum;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitClassicalToQuantum(this);
    }
}