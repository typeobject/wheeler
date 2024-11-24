package com.typeobject.wheeler.compiler.ast.classical.types;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;

public abstract class ClassicalType extends Type {
  private final String name;
  private final List<Type> typeArguments;
  private final boolean isPrimitive;

  protected ClassicalType(Position position, List<Annotation> annotations,
                          String name, List<Type> typeArguments, boolean isPrimitive) {
    super(position, annotations);
    this.name = name;
    this.typeArguments = typeArguments;
    this.isPrimitive = isPrimitive;
  }

  public String getName() {
    return name;
  }

  public List<Type> getTypeArguments() {
    return typeArguments;
  }

  public boolean isPrimitive() {
    return isPrimitive;
  }

  @Override
  public boolean isClassical() {
    return true;
  }
}