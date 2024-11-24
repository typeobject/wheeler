package com.typeobject.wheeler.compiler.ast.base;

import com.typeobject.wheeler.compiler.ast.Node;
import java.util.List;

// Declarations
public abstract sealed class Declaration extends Node {
  private final List<Modifier> modifiers;
  private final String identifier;
}
