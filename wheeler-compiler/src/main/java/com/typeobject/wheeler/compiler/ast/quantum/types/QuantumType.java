// QuantumType.java
package com.typeobject.wheeler.compiler.ast.quantum.types;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;

public final class QuantumType extends Type {
  private final QuantumTypeKind kind;

  public QuantumType(Position position, List<Annotation> annotations, QuantumTypeKind kind) {
    super(position, annotations);
    this.kind = kind;
  }

  public QuantumTypeKind getKind() {
    return kind;
  }

  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitQuantumType(this);
  }
}