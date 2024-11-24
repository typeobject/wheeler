package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.List;

public final class ClassDeclaration extends Declaration {
  private final Type superClass;
  private final List<Type> interfaces;
  private final List<Declaration> members;
  private final ComputationType computationType; // CLASSICAL, QUANTUM, HYBRID

  public boolean isQuantum() {
    return computationType == ComputationType.QUANTUM;
  }
}
