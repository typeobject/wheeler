package com.typeobject.wheeler.compiler.ast.base;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;

public abstract class Type extends Node {
  protected Type(Position position, List<Annotation> annotations) {
    super(position, annotations);
  }

  public boolean isQubit() {
    return false;
  }

  public boolean isQuantum() {
    return false;
  }

  public boolean isClassical() {
    return false;
  }
}