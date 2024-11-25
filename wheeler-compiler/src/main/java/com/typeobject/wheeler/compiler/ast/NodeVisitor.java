// NodeVisitor.java
package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.classical.declarations.ClassDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.declarations.ConstructorDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.declarations.FieldDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.declarations.MethodDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.declarations.PackageDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.expressions.ArrayAccess;
import com.typeobject.wheeler.compiler.ast.classical.expressions.ArrayCreationExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.ArrayInitializer;
import com.typeobject.wheeler.compiler.ast.classical.expressions.Assignment;
import com.typeobject.wheeler.compiler.ast.classical.expressions.BinaryExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.CastExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.InstanceOfExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.LambdaExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.LiteralExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.MethodCall;
import com.typeobject.wheeler.compiler.ast.classical.expressions.MethodReferenceExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.ObjectCreationExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.TernaryExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.UnaryExpression;
import com.typeobject.wheeler.compiler.ast.classical.expressions.VariableReference;
import com.typeobject.wheeler.compiler.ast.classical.statements.CatchClause;
import com.typeobject.wheeler.compiler.ast.classical.statements.DoWhileStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.ForStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.IfStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.TryStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.VariableDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.statements.WhileStatement;
import com.typeobject.wheeler.compiler.ast.classical.types.ArrayType;
import com.typeobject.wheeler.compiler.ast.classical.types.PrimitiveType;
import com.typeobject.wheeler.compiler.ast.classical.types.TypeParameter;
import com.typeobject.wheeler.compiler.ast.classical.types.WildcardType;
import com.typeobject.wheeler.compiler.ast.memory.AllocationStatement;
import com.typeobject.wheeler.compiler.ast.memory.CleanBlock;
import com.typeobject.wheeler.compiler.ast.memory.DeallocationStatement;
import com.typeobject.wheeler.compiler.ast.memory.GarbageCollectionStatement;
import com.typeobject.wheeler.compiler.ast.memory.UncomputeBlock;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QuantumArrayAccess;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QuantumCastExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QuantumRegisterAccess;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitReference;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.StateExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.TensorProduct;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumBlock;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumGateApplication;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumIfStatement;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumMeasurement;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumStatePreparation;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumWhileStatement;

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