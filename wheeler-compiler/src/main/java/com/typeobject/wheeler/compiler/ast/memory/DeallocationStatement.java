package com.typeobject.wheeler.compiler.ast.memory;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import java.util.List;

public final class DeallocationStatement extends Statement {
    private final Expression target;

    public DeallocationStatement(Position position, List<Annotation> annotations,
                                 Expression target) {
        super(position, annotations);
        this.target = target;
    }

    public Expression getTarget() {
        return target;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitDeallocationStatement(this);
    }
}