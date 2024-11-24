package com.typeobject.wheeler.compiler.ast.classical;

import java.util.List;
import java.util.ArrayList;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;

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