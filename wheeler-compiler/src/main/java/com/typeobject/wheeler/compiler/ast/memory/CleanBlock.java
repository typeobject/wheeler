package com.typeobject.wheeler.compiler.ast.memory;

import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import java.util.List;

public final class CleanBlock extends Statement {
  private final List<QubitExpression> qubits;
}
