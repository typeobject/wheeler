package com.typeobject.wheeler.compiler.ast.classical;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Statement;

import java.util.ArrayList;
import java.util.List;

public class Block extends Statement {
    private final List<Statement> statements;

    public Block(Position position, List<Annotation> annotations, List<Statement> statements) {
        super(position, annotations);
        this.statements = statements != null ? statements : new ArrayList<>();
    }

    public List<Statement> getStatements() {
        return statements;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitBlock(this);
    }
}