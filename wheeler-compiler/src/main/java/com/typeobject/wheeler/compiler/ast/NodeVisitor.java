package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.classical.declarations.ClassDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.declarations.MethodDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.statements.IfStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.WhileStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.ReturnStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.VariableDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.expressions.*;
import com.typeobject.wheeler.compiler.ast.classical.types.*;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.*;
import com.typeobject.wheeler.compiler.ast.quantum.statements.*;
import com.typeobject.wheeler.compiler.ast.quantum.types.*;
import com.typeobject.wheeler.compiler.ast.quantum.gates.*;
import com.typeobject.wheeler.compiler.ast.memory.*;

/**
 * Visitor interface for the Wheeler AST. Implements the visitor pattern for both
 * classical and quantum nodes.
 * @param <T> The return type of the visitor's methods
 */
public interface NodeVisitor<T> {
  // Top-level program structure
  T visitCompilationUnit(CompilationUnit node);
  T visitImportDeclaration(ImportDeclaration node);
  T visitPackageDeclaration(PackageDeclaration node);

  // Classical declarations
  T visitClassDeclaration(ClassDeclaration node);
  T visitMethodDeclaration(MethodDeclaration node);
  T visitConstructorDeclaration(ConstructorDeclaration node);
  T visitFieldDeclaration(FieldDeclaration node);
  T visitVariableDeclaration(VariableDeclaration node);
  T visitParameter(Parameter node);

  // Classical statements
  T visitBlock(Block node);
  T visitIfStatement(IfStatement node);
  T visitWhileStatement(WhileStatement node);
  T visitForStatement(ForStatement node);
  T visitDoWhileStatement(DoWhileStatement node);
  T visitReturnStatement(ReturnStatement node);
  T visitBreakStatement(BreakStatement node);
  T visitContinueStatement(ContinueStatement node);
  T visitExpressionStatement(ExpressionStatement node);
  T visitAssertStatement(AssertStatement node);
  T visitSynchronizedStatement(SynchronizedStatement node);
  T visitTryStatement(TryStatement node);
  T visitThrowStatement(ThrowStatement node);

  // Classical expressions
  T visitBinaryExpression(BinaryExpression node);
  T visitUnaryExpression(UnaryExpression node);
  T visitLiteralExpression(LiteralExpression node);
  T visitVariableReference(VariableReference node);
  T visitMethodCall(MethodCall node);
  T visitArrayAccess(ArrayAccess node);
  T visitAssignment(Assignment node);
  T visitInstanceOf(InstanceOfExpression node);
  T visitCast(CastExpression node);
  T visitTernary(TernaryExpression node);
  T visitLambda(LambdaExpression node);
  T visitMethodReference(MethodReferenceExpression node);
  T visitArrayCreation(ArrayCreationExpression node);
  T visitObjectCreation(ObjectCreationExpression node);

  // Classical types
  T visitPrimitiveType(PrimitiveType node);
  T visitClassType(ClassType node);
  T visitArrayType(ArrayType node);
  T visitTypeParameter(TypeParameter node);
  T visitWildcardType(WildcardType node);

  // Quantum expressions
  T visitQubitReference(QubitReference node);
  T visitTensorProduct(TensorProduct node);
  T visitStateExpression(StateExpression node);
  T visitQuantumRegisterAccess(QuantumRegisterAccess node);
  T visitQuantumArrayAccess(QuantumArrayAccess node);
  T visitQuantumCast(QuantumCastExpression node);

  // Quantum statements
  T visitQuantumBlock(QuantumBlock node);
  T visitQuantumGateApplication(QuantumGateApplication node);
  T visitQuantumMeasurement(QuantumMeasurement node);
  T visitQuantumStatePreparation(QuantumStatePreparation node);
  T visitQuantumIfStatement(QuantumIfStatement node);
  T visitQuantumWhileStatement(QuantumWhileStatement node);
  T visitQuantumForStatement(QuantumForStatement node);
  T visitQuantumRegisterDeclaration(QuantumRegisterDeclaration node);
  T visitQuantumAncillaDeclaration(QuantumAncillaDeclaration node);
  T visitQuantumBarrier(QuantumBarrier node);

  // Quantum types
  T visitQuantumType(QuantumType node);
  T visitQuantumArrayType(QuantumArrayType node);
  T visitQuantumRegisterType(QuantumRegisterType node);

  // Quantum gates
  T visitStandardGate(StandardGate node);
  T visitControlledGate(ControlledGate node);
  T visitCustomGate(CustomGate node);
  T visitInverseGate(InverseGate node);
  T visitParameterizedGate(ParameterizedGate node);

  // Memory management
  T visitCleanBlock(CleanBlock node);
  T visitUncomputeBlock(UncomputeBlock node);
  T visitAllocationStatement(AllocationStatement node);
  T visitDeallocationStatement(DeallocationStatement node);
  T visitGarbageCollection(GarbageCollectionStatement node);

  // Hybrid expressions and statements
  T visitHybridBlock(HybridBlock node);
  T visitClassicalToQuantum(ClassicalToQuantumConversion node);
  T visitQuantumToClassical(QuantumToClassicalConversion node);
  T visitHybridIfStatement(HybridIfStatement node);
  T visitHybridWhileStatement(HybridWhileStatement node);

  // Advanced quantum features
  T visitQuantumCircuit(QuantumCircuit node);
  T visitQuantumFunction(QuantumFunction node);
  T visitQuantumOracle(QuantumOracle node);
  T visitQuantumTeleport(QuantumTeleport node);
  T visitEntanglementOperation(EntanglementOperation node);

  // Error handling and utility nodes
  T visitErrorNode(ErrorNode node);
  T visitComment(CommentNode node);
  T visitAnnotation(Annotation node);
  T visitModifier(Modifier node);
  T visitDocumentation(Documentation node);

  // Default implementations for convenience
  default T visitChildren(Node node) {
    throw new UnsupportedOperationException(
            "visitChildren not implemented for " + node.getClass().getSimpleName());
  }

  default T defaultValue() {
    return null;
  }

  /**
   * Helper method to visit a node that might be null
   */
  default T visitNullable(Node node) {
    return node != null ? node.accept(this) : defaultValue();
  }
}