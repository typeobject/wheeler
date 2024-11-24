package com.typeobject.wheeler.compiler.ast.visitors;

public class TypeCheckingVisitor implements NodeVisitor<Type> {
  private final TypeEnvironment env;
  private final ErrorReporter errors;

  @Override
  public Type visitQuantumGateApplication(QuantumGateApplication node) {
    // Validate gate application
    QuantumGate gate = node.getGate();
    List<QubitExpression> targets = node.getTargets();

    // Check arity
    if (gate.getArity() != targets.size()) {
      errors.report(
          node.getPosition(),
          "Gate "
              + gate.getName()
              + " expects "
              + gate.getArity()
              + " qubits but got "
              + targets.size());
      return Type.ERROR;
    }

    // Check target types
    for (QubitExpression target : targets) {
      Type type = target.accept(this);
      if (!type.isQubit() && !type.isQuantumRegister()) {
        errors.report(target.getPosition(), "Gate target must be qubit or quantum register");
        return Type.ERROR;
      }
    }

    return Type.UNIT;
  }

  // Other visitor methods...
}
