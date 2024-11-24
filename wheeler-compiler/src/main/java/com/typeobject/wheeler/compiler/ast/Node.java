// Node.java
package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;
import java.util.ArrayList;

public abstract sealed class Node
        permits CompilationUnit, Declaration, Expression, Statement, Type {

  private final Position position;
  private final List<Annotation> annotations;

  protected Node(Position position, List<Annotation> annotations) {
    this.position = position;
    this.annotations = annotations != null ? annotations : new ArrayList<>();
  }

  public Position getPosition() {
    return position;
  }

  public List<Annotation> getAnnotations() {
    return annotations;
  }

  public abstract <T> T accept(NodeVisitor<T> visitor);
}