package com.typeobject.wheeler.compiler.ast.quantum.expressions;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class QuantumRegisterAccess extends QubitExpression {
    private final Expression register;
    private final Expression index;

    public QuantumRegisterAccess(Position position, List<Annotation> annotations,
                                 Expression register, Expression index) {
        super(position, annotations);
        this.register = register;
        this.index = index;
    }

    public Expression getRegister() {
        return register;
    }

    public Expression getIndex() {
        return index;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumRegisterAccess(this);
    }
}