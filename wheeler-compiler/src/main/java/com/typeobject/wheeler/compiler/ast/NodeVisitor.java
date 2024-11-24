package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.classical.declarations.ClassDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.declarations.MethodDeclaration;
import com.typeobject.wheeler.compiler.ast.hybrid.HybridBlock;
import com.typeobject.wheeler.compiler.ast.memory.CleanBlock;
import com.typeobject.wheeler.compiler.ast.memory.UncomputeBlock;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitReference;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.StateExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.TensorProduct;
import com.typeobject.wheeler.compiler.ast.quantum.statements.*;

// Visitor pattern
public interface NodeVisitor<T> {
  // Program structure
  T visitCompilationUnit(CompilationUnit node);

  T visitClassDeclaration(ClassDeclaration node);

  T visitMethodDeclaration(MethodDeclaration node);

  // Classical constructs
  T visitBlock(Block node);

  T visitIfStatement(IfStatement node);

  T visitWhileStatement(WhileStatement node);

  // Quantum constructs
  T visitQuantumBlock(QuantumBlock node);

  T visitQuantumGateApplication(QuantumGateApplication node);

  T visitQuantumMeasurement(QuantumMeasurement node);

  T visitQuantumStatePreparation(QuantumStatePreparation node);

  T visitQuantumIfStatement(QuantumIfStatement node);

  T visitQuantumWhileStatement(QuantumWhileStatement node);

  // Hybrid constructs
  T visitHybridBlock(HybridBlock node);

  // Memory management
  T visitUncomputeBlock(UncomputeBlock node);

  T visitCleanBlock(CleanBlock node);

  // Expressions
  T visitQubitReference(QubitReference node);

  T visitStateExpression(StateExpression node);

  T visitTensorProduct(TensorProduct node);
}
