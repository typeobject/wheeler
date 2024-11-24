package com.typeobject.wheeler.compiler.ast.classical.statements;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Statement;

public final class ContinueStatement extends Statement {
    private final String label;

    public ContinueStatement(Position position, List<Annotation> annotations, String label) {
        super(position, annotations);
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitContinueStatement(this);
    }
}