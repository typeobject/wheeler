package com.typeobject.wheeler.compiler.ast.quantum.types;

import com.typeobject.wheeler.compiler.ast.QuantumTypeKind;
import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.List;

public final class QuantumType extends Type {
  private final QuantumTypeKind kind; // QUBIT, QUREG, STATE, ORACLE
  private final List<Type> typeArguments;

  @Override
  public boolean isQuantum() {
    return true;
  }

  @Override
  public boolean isClassical() {
    return false;
  }

  @Override
  public boolean isHybrid() {
    return false;
  }
}
