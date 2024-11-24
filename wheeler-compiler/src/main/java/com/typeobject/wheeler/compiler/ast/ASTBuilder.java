package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.classical.declarations.MethodDeclaration;
import com.typeobject.wheeler.compiler.ast.quantum.gates.QuantumGate;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumGateApplication;
import java.util.ArrayList;
import java.util.List;

// Builder pattern for creating AST nodes
public class ASTBuilder {
  private final SourcePosition position;

  public ClassDeclaration.Builder classDeclaration(String name) {
    return new ClassDeclaration.Builder(position, name);
  }

  public MethodDeclaration.Builder methodDeclaration(String name) {
    return new MethodDeclaration.Builder(position, name);
  }

  public QuantumGateApplication.Builder gateApplication(QuantumGate gate) {
    return new QuantumGateApplication.Builder(position, gate);
  }

  // Additional builder methods...

  // Example builder inner class
  public static class ClassDeclaration {
    public static class Builder {
      private final Position position;
      private final String name;
      private List<Modifier> modifiers = new ArrayList<>();
      private ComputationType computationType = ComputationType.CLASSICAL;

      public Builder(Position position, String name) {
        this.position = position;
        this.name = name;
      }

      public Builder addModifier(Modifier modifier) {
        modifiers.add(modifier);
        return this;
      }

      public Builder setComputationType(ComputationType type) {
        this.computationType = type;
        return this;
      }

      public ClassDeclaration build() {
        return new ClassDeclaration(
            position,
            new ArrayList<>(), // annotations
            modifiers,
            name,
            computationType,
            null, // superClass
            new ArrayList<>(), // interfaces
            new ArrayList<>() // members
            );
      }
    }
  }
}
