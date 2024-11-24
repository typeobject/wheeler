package com.typeobject.wheeler.compiler.ast;

import java.util.ArrayList;
import java.util.List;

/**
 * Base class for all AST nodes.
 */
public abstract class Node {
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