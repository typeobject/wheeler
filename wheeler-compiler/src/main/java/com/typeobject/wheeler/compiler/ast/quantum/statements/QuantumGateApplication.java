package com.typeobject.wheeler.compiler.ast.quantum.statements;

import com.typeobject.wheeler.compiler.ast.QuantumStatement;
import com.typeobject.wheeler.compiler.ast.QubitExpression;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import com.typeobject.wheeler.compiler.ast.quantum.gates.QuantumGate;
import java.util.List;

public final class QuantumGateApplication extends QuantumStatement {
  private final QuantumGate gate;
  private final List<QubitExpression> targets;
  private final Expression parameter; // For parameterized gates
}
