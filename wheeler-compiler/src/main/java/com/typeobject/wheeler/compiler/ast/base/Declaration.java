// Declaration.java
package com.typeobject.wheeler.compiler.ast.base;

import java.util.List;
import java.util.ArrayList;

import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.classical.declarations.*;

public abstract sealed class Declaration extends Node
        permits ClassDeclaration, MethodDeclaration {

  private final List<Modifier> modifiers;
  private final String name;

  protected Declaration(Position position, List<Annotation> annotations,
                        List<Modifier> modifiers, String name) {
    super(position, annotations);
    this.modifiers = modifiers != null ? modifiers : new ArrayList<>();
    this.name = name;
  }

  public List<Modifier> getModifiers() {
    return modifiers;
  }

  public String getName() {
    return name;
  }
}