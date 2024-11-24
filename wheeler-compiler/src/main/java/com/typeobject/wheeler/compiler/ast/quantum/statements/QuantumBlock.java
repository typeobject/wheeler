package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.visitors.NodeVisitor;

public final class QuantumBlock extends Statement {
  private final List<Statement> statements;

  public QuantumBlock(Position position, List<Annotation> annotations, List<Statement> statements) {
    super(position, annotations);
    this.statements = statements;
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

    public Builder addStatement(Statement stmt) {
      statements.add(stmt);
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
