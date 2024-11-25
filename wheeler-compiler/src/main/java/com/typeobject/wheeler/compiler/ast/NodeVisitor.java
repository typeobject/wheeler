package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.classical.declarations.*;
import com.typeobject.wheeler.compiler.ast.classical.expressions.*;
import com.typeobject.wheeler.compiler.ast.classical.statements.*;
import com.typeobject.wheeler.compiler.ast.classical.types.*;
import com.typeobject.wheeler.compiler.ast.memory.*;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.*;
import com.typeobject.wheeler.compiler.ast.quantum.statements.*;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;

public interface NodeVisitor<T> {
    // Documentation
    T visitDocumentation(Documentation node);

    // Top-level declarations
    T visitCompilationUnit(CompilationUnit node);
    T visitImportDeclaration(ImportDeclaration node);
    T visitPackageDeclaration(PackageDeclaration node);

    // Class declarations
    T visitClassDeclaration(ClassDeclaration node);
    T visitMethodDeclaration(MethodDeclaration node);
    T visitConstructorDeclaration(ConstructorDeclaration node);
    T visitFieldDeclaration(FieldDeclaration node);

    // Control structures
    T visitBlock(Block node);
    T visitIfStatement(IfStatement node);
    T visitWhileStatement(WhileStatement node);
    T visitForStatement(ForStatement node);
    T visitDoWhileStatement(DoWhileStatement node);
    T visitTryStatement(TryStatement node);
    T visitCatchClause(CatchClause node);
    T visitVariableDeclaration(VariableDeclaration node);

    // Classical expressions
    T visitBinaryExpression(BinaryExpression node);
    T visitUnaryExpression(UnaryExpression node);
    T visitLiteralExpression(LiteralExpression node);
    T visitArrayAccess(ArrayAccess node);
    T visitArrayInitializer(ArrayInitializer node);
    T visitAssignment(Assignment node);
    T visitMethodCall(MethodCall node);
    T visitVariableReference(VariableReference node);
    T visitInstanceOf(InstanceOfExpression node);
    T visitCast(CastExpression node);
    T visitTernary(TernaryExpression node);
    T visitLambda(LambdaExpression node);
    T visitMethodReference(MethodReferenceExpression node);
    T visitArrayCreation(ArrayCreationExpression node);
    T visitObjectCreation(ObjectCreationExpression node);

    // Types
    T visitPrimitiveType(PrimitiveType node);
    T visitClassType(ClassType node);
    T visitArrayType(ArrayType node);
    T visitTypeParameter(TypeParameter node);
    T visitWildcardType(WildcardType node);
    T visitQuantumType(QuantumType node);  // Added new visitor method

    // Quantum statements
    T visitQuantumBlock(QuantumBlock node);
    T visitQuantumGateApplication(QuantumGateApplication node);
    T visitQuantumMeasurement(QuantumMeasurement node);
    T visitQuantumStatePreparation(QuantumStatePreparation node);
    T visitQuantumIfStatement(QuantumIfStatement node);
    T visitQuantumWhileStatement(QuantumWhileStatement node);

    // Quantum expressions
    T visitQubitReference(QubitReference node);
    T visitTensorProduct(TensorProduct node);
    T visitStateExpression(StateExpression node);
    T visitQuantumRegisterAccess(QuantumRegisterAccess node);
    T visitQuantumArrayAccess(QuantumArrayAccess node);
    T visitQuantumCastExpression(QuantumCastExpression node);

    // Memory management
    T visitCleanBlock(CleanBlock node);
    T visitUncomputeBlock(UncomputeBlock node);
    T visitAllocationStatement(AllocationStatement node);
    T visitDeallocationStatement(DeallocationStatement node);
    T visitGarbageCollection(GarbageCollectionStatement node);
}