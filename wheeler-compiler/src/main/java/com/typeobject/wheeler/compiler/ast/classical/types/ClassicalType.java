package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.List;

public final class ClassicalType extends Type {
  private final String name;
  private final List<Type> typeArguments;
  private final boolean isPrimitive;

  @Override
  public boolean isQuantum() {
    return false;
  }

  @Override
  public boolean isClassical() {
    return true;
  }

  @Override
  public boolean isHybrid() {
    return false;
  }
}
