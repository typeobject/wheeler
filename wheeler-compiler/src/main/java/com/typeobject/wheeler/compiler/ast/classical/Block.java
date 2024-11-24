package com.typeobject.wheeler.compiler.ast.classical;

import com.typeobject.wheeler.compiler.ast.base.Statement;
import java.util.List;

public final class Block extends Statement {
  private final List<Statement> statements;
}
