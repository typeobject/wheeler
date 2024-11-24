package com.typeobject.wheeler.compiler.ast.base;

import com.typeobject.wheeler.compiler.ast.Node;

// Type System
public abstract sealed class Type extends Node {
  public abstract boolean isQuantum();

  public abstract boolean isClassical();

  public abstract boolean isHybrid();
}
