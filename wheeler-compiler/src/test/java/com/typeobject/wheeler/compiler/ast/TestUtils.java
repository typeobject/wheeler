package com.typeobject.wheeler.compiler.ast;

public class TestUtils {
  public static Position testPosition() {
    return new Position("Test.wheel", 1, 1);
  }

  public static ASTBuilder.ClassDeclaration createTestClass(String name) {
    return new ClassDeclaration.Builder(testPosition())
        .setName(name)
        .addModifier(Modifier.PUBLIC)
        .build();
  }

  public static QuantumBlock createBellCircuit() {
    return new QuantumBlock.Builder(testPosition())
        .addStatement(
            new QuantumGateApplication.Builder(testPosition())
                .setGate(StandardGate.HADAMARD)
                .addTarget(new QubitReference("q", 0))
                .build())
        .addStatement(
            new QuantumGateApplication.Builder(testPosition())
                .setGate(StandardGate.CNOT)
                .addTarget(new QubitReference("q", 0))
                .addTarget(new QubitReference("q", 1))
                .build())
        .build();
  }
}
