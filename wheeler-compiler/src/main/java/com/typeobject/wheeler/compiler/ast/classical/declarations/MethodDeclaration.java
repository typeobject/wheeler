package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.ComputationType;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Reversible;
import java.util.List;

public final class MethodDeclaration extends Declaration implements Reversible {
  private final Type returnType;
  private final List<Parameter> parameters;
  private final Block body;
  private final ComputationType computationType;
  private final boolean isPure;
  private final boolean isRev;

  @Override
  public boolean isReversible() {
    return isRev || isPure;
  }
}
