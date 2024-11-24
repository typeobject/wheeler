package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.*;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class ClassDeclaration extends Declaration {
  private final Type superClass;
  private final List<Type> interfaces;
  private final List<Declaration> members;
  private final ComputationType computationType;

  public ClassDeclaration(Position position, List<Annotation> annotations, List<Modifier> modifiers,
                          String name, Type superClass, List<Type> interfaces,
                          List<Declaration> members, ComputationType computationType) {
    super(position, annotations, modifiers, name);
    this.superClass = superClass;
    this.interfaces = interfaces;
    this.members = members;
    this.computationType = computationType;
  }

  public Type getSuperClass() {
    return superClass;
  }

  public List<Type> getInterfaces() {
    return interfaces;
  }

  public List<Declaration> getMembers() {
    return members;
  }

  public boolean isQuantum() {
    return computationType == ComputationType.QUANTUM;
  }

  @Override
  public <T> T accept(NodeVisitor<T> visitor) {
    return visitor.visitClassDeclaration(this);
  }
}