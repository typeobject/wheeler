// QuantumBlock.java
package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import java.util.ArrayList;
import java.util.List;

public final class QuantumBlock extends QuantumStatement {
    private final List<Statement> statements;

    public QuantumBlock(Position position, List<Annotation> annotations,
                        List<Statement> statements) {
        super(position, annotations);
        this.statements = statements != null ? statements : new ArrayList<>();
    }

    public List<Statement> getStatements() {
        return statements;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitQuantumBlock(this);
    }

    public static class Builder {
        private final Position position;
        private final List<Statement> statements = new ArrayList<>();
        private final List<Annotation> annotations = new ArrayList<>();

        public Builder(Position position) {
            this.position = position;
        }

        public Builder addStatement(Statement statement) {
            statements.add(statement);
            return this;
        }

        public Builder addAnnotation(Annotation annotation) {
            annotations.add(annotation);
            return this;
        }

        public QuantumBlock build() {
            return new QuantumBlock(position, annotations, statements);
        }
    }
}