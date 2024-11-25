package com.typeobject.wheeler.compiler.analysis;


import com.typeobject.wheeler.compiler.ErrorReporter;
import com.typeobject.wheeler.compiler.ast.CommentNode;
import com.typeobject.wheeler.compiler.ast.CompilationUnit;
import com.typeobject.wheeler.compiler.ast.Documentation;
import com.typeobject.wheeler.compiler.ast.ErrorNode;
import com.typeobject.wheeler.compiler.ast.ImportDeclaration;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Type;
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
import com.typeobject.wheeler.compiler.ast.classical.expressions.AssignmentOperator;
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
import com.typeobject.wheeler.compiler.ast.classical.statements.AssertStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.BreakStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.CatchClause;
import com.typeobject.wheeler.compiler.ast.classical.statements.ContinueStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.DoWhileStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.ExpressionStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.ForStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.IfStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.ReturnStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.SynchronizedStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.ThrowStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.TryStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.VariableDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.statements.WhileStatement;
import com.typeobject.wheeler.compiler.ast.classical.types.ArrayType;
import com.typeobject.wheeler.compiler.ast.classical.types.ClassType;
import com.typeobject.wheeler.compiler.ast.classical.types.ClassicalType;
import com.typeobject.wheeler.compiler.ast.classical.types.PrimitiveType;
import com.typeobject.wheeler.compiler.ast.classical.types.TypeParameter;
import com.typeobject.wheeler.compiler.ast.classical.types.WildcardType;
import com.typeobject.wheeler.compiler.ast.hybrid.ClassicalToQuantumConversion;
import com.typeobject.wheeler.compiler.ast.hybrid.HybridBlock;
import com.typeobject.wheeler.compiler.ast.hybrid.HybridIfStatement;
import com.typeobject.wheeler.compiler.ast.hybrid.HybridWhileStatement;
import com.typeobject.wheeler.compiler.ast.hybrid.QuantumToClassicalConversion;
import com.typeobject.wheeler.compiler.ast.memory.AllocationStatement;
import com.typeobject.wheeler.compiler.ast.memory.CleanBlock;
import com.typeobject.wheeler.compiler.ast.memory.DeallocationStatement;
import com.typeobject.wheeler.compiler.ast.memory.GarbageCollectionStatement;
import com.typeobject.wheeler.compiler.ast.memory.UncomputeBlock;
import com.typeobject.wheeler.compiler.ast.quantum.ComplexNumber;
import com.typeobject.wheeler.compiler.ast.quantum.EntanglementOperation;
import com.typeobject.wheeler.compiler.ast.quantum.QuantumCircuit;
import com.typeobject.wheeler.compiler.ast.quantum.QuantumFunction;
import com.typeobject.wheeler.compiler.ast.quantum.QuantumOracle;
import com.typeobject.wheeler.compiler.ast.quantum.QuantumTeleport;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.QuantumAncillaDeclaration;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.QuantumRegisterDeclaration;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QuantumArrayAccess;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QuantumCastExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QuantumRegisterAccess;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.QubitReference;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.StateExpression;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.TensorProduct;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumBarrier;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumBlock;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumForStatement;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumGateApplication;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumIfStatement;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumMeasurement;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumStatePreparation;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumWhileStatement;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumArrayType;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumRegisterType;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumTypeKind;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TypeChecker implements NodeVisitor<Type> {
    private final ErrorReporter errors;
    private final Map<String, TypeEnvironment> typeEnvironments;
    private final Deque<String> scopeStack;
    private TypeEnvironment currentEnv;
    private Type currentReturnType;
    private boolean inQuantumContext;
    private boolean inCleanBlock;

    public TypeChecker(ErrorReporter errors) {
        this.errors = errors;
        this.typeEnvironments = new HashMap<>();
        this.scopeStack = new ArrayDeque<>();
        this.currentEnv = new TypeEnvironment(null, null);
        this.inQuantumContext = false;
        this.inCleanBlock = false;

        initializeBuiltinTypes();
    }

    private void initializeBuiltinTypes() {
        // Add primitive types
        currentEnv.define("boolean", new PrimitiveType(null, List.of(), PrimitiveType.Kind.BOOLEAN));
        currentEnv.define("byte", new PrimitiveType(null, List.of(), PrimitiveType.Kind.BYTE));
        currentEnv.define("short", new PrimitiveType(null, List.of(), PrimitiveType.Kind.SHORT));
        currentEnv.define("int", new PrimitiveType(null, List.of(), PrimitiveType.Kind.INT));
        currentEnv.define("long", new PrimitiveType(null, List.of(), PrimitiveType.Kind.LONG));
        currentEnv.define("float", new PrimitiveType(null, List.of(), PrimitiveType.Kind.FLOAT));
        currentEnv.define("double", new PrimitiveType(null, List.of(), PrimitiveType.Kind.DOUBLE));
        currentEnv.define("char", new PrimitiveType(null, List.of(), PrimitiveType.Kind.CHAR));
        currentEnv.define("void", new PrimitiveType(null, List.of(), PrimitiveType.Kind.VOID));

        // Add quantum types
        currentEnv.define("qubit", new QuantumType(null, List.of(), QuantumTypeKind.QUBIT));
        currentEnv.define("qureg", new QuantumType(null, List.of(), QuantumTypeKind.QUREG));
        currentEnv.define("state", new QuantumType(null, List.of(), QuantumTypeKind.STATE));
    }

    public Type visitQuantumType(QuantumType node) {
        QuantumTypeKind kind = node.getKind();

        // Validate quantum type based on kind
        switch (kind) {
            case QUBIT:
                // Single qubit validation
                break;
            case QUREG:
                // Check register size
                if (node.getSize() <= 0) {
                    errors.report("Quantum register must have positive size", node.getPosition());
                }
                break;
            case STATE:
                // Validate state vector properties
                break;
        }

        return node;
    }

    @Override
    public Type visitParameter(Parameter parameter) {
        Type paramType = parameter.getType().accept(this);
        currentEnv.define(parameter.getName(), paramType);
        return paramType;
    }


    // Quantum-specific validations
    private void validateQuantumOperation(QubitExpression expr) {
        if (!inQuantumContext) {
            errors.report("Quantum operations must be within a quantum context", expr.getPosition());
        }
    }

    private void validateStateVector(List<ComplexNumber> coefficients, int numQubits) {
        int expectedDimension = 1 << numQubits;
        if (coefficients.size() != expectedDimension) {
            errors.report("Invalid state vector dimension", null);
            return;
        }

        // Check normalization
        double sumSquared = coefficients.stream()
                .mapToDouble(c -> c.magnitudeSquared())
                .sum();

        if (Math.abs(sumSquared - 1.0) > 1e-10) {
            errors.report("State vector is not normalized", null);
        }
    }

    private void enterScope(String scopeName) {
        TypeEnvironment newEnv = new TypeEnvironment(currentEnv, currentEnv.getUnitType());
        typeEnvironments.put(scopeName, newEnv);
        scopeStack.push(scopeName);
        currentEnv = newEnv;
    }

    private void exitScope() {
        if (!scopeStack.isEmpty()) {
            scopeStack.pop();
            currentEnv = !scopeStack.isEmpty() ?
                    typeEnvironments.get(scopeStack.peek()) :
                    new TypeEnvironment(null, null);
        }
    }

    // Main entry point
    public void check(CompilationUnit unit) {
        unit.accept(this);
    }

    @Override
    public Type visitCompilationUnit(CompilationUnit node) {
        String unitName = node.getPackage() != null ?
                node.getPackage() + "." + node.getDeclarations().get(0).getName() :
                node.getDeclarations().get(0).getName();
        enterScope(unitName);

        // Process imports first
        for (ImportDeclaration imp : node.getImports()) {
            imp.accept(this);
        }

        // Then check all declarations
        for (Declaration decl : node.getDeclarations()) {
            decl.accept(this);
        }

        exitScope();
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitClassDeclaration(ClassDeclaration node) {
        enterScope(node.getName());

        // Check superclass if present
        if (node.getSuperClass() != null) {
            Type superType = node.getSuperClass().accept(this);
            if (!(superType instanceof ClassType)) {
                errors.report("Superclass must be a classical type", node.getPosition());
            }
        }

        // Check implemented interfaces
        for (Type iface : node.getInterfaces()) {
            Type ifaceType = iface.accept(this);
            if (!(ifaceType instanceof ClassType)) {
                errors.report("Implemented interface must be a classical type", iface.getPosition());
            }
        }

        // Process class members
        for (Declaration member : node.getMembers()) {
            member.accept(this);
        }

        exitScope();
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitMethodDeclaration(MethodDeclaration node) {
        enterScope(node.getName());
        Type prevReturnType = currentReturnType;
        boolean prevQuantumContext = inQuantumContext;

        // Set method context
        currentReturnType = node.getReturnType().accept(this);
        inQuantumContext = node.getModifiers().contains(Modifier.QUANTUM);

        // Check parameters
        for (Parameter param : node.getParameters()) {
            Type paramType = param.getType().accept(this);
            currentEnv.define(param.getName(), paramType);
        }

        // Check method body
        if (node.getBody() != null) {
            Type bodyType = node.getBody().accept(this);
            if (!isAssignable(currentReturnType, bodyType)) {
                errors.report("Method body type incompatible with declared return type",
                        node.getBody().getPosition());
            }
        }

        // Restore previous context
        currentReturnType = prevReturnType;
        inQuantumContext = prevQuantumContext;
        exitScope();

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitBlock(Block node) {
        enterScope("block" + scopeStack.size());

        for (Statement stmt : node.getStatements()) {
            stmt.accept(this);
        }

        exitScope();
        return currentReturnType;
    }

    @Override
    public Type visitQuantumBlock(QuantumBlock node) {
        enterScope("quantum" + scopeStack.size());
        boolean prevQuantumContext = inQuantumContext;
        inQuantumContext = true;

        for (Statement stmt : node.getStatements()) {
            stmt.accept(this);
        }

        inQuantumContext = prevQuantumContext;
        exitScope();
        return currentReturnType;
    }

    @Override
    public Type visitIfStatement(IfStatement node) {
        Type condType = node.getCondition().accept(this);
        if (!isBoolean(condType)) {
            errors.report("If condition must be boolean", node.getCondition().getPosition());
        }

        node.getThenStatement().accept(this);
        if (node.getElseStatement() != null) {
            node.getElseStatement().accept(this);
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitWhileStatement(WhileStatement node) {
        Type condType = node.getCondition().accept(this);
        if (!isBoolean(condType)) {
            errors.report("While condition must be boolean", node.getCondition().getPosition());
        }

        node.getBody().accept(this);
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitVariableDeclaration(VariableDeclaration node) {
        Type declaredType = node.getType().accept(this);

        if (node.getInitializer() != null) {
            Type initType = node.getInitializer().accept(this);
            if (!isAssignable(declaredType, initType)) {
                errors.report("Cannot initialize variable of type " + declaredType +
                                " with expression of type " + initType,
                        node.getInitializer().getPosition());
            }
        }

        currentEnv.define(node.getName(), declaredType);
        return declaredType;
    }

    @Override
    public Type visitBinaryExpression(BinaryExpression node) {
        Type leftType = node.getLeft().accept(this);
        Type rightType = node.getRight().accept(this);

        switch (node.getOperator()) {
            case ADD, SUBTRACT, MULTIPLY, DIVIDE, MODULO -> {
                if (!isNumeric(leftType) || !isNumeric(rightType)) {
                    errors.report("Arithmetic operators require numeric operands",
                            node.getPosition());
                    return currentEnv.getErrorType();
                }
                return promoteNumeric(leftType, rightType);
            }
            case EQUAL, NOT_EQUAL -> {
                if (!isComparable(leftType, rightType)) {
                    errors.report("Types are not comparable", node.getPosition());
                    return currentEnv.getErrorType();
                }
                return currentEnv.getBooleanType();
            }
            case LESS_THAN, LESS_EQUAL, GREATER_THAN, GREATER_EQUAL -> {
                if (!isOrdered(leftType) || !isOrdered(rightType)) {
                    errors.report("Comparison operators require ordered types",
                            node.getPosition());
                    return currentEnv.getErrorType();
                }
                return currentEnv.getBooleanType();
            }
            case LOGICAL_AND, LOGICAL_OR -> {
                if (!isBoolean(leftType) || !isBoolean(rightType)) {
                    errors.report("Logical operators require boolean operands",
                            node.getPosition());
                    return currentEnv.getErrorType();
                }
                return currentEnv.getBooleanType();
            }
            default -> {
                errors.report("Unsupported binary operator: " + node.getOperator(),
                        node.getPosition());
                return currentEnv.getErrorType();
            }
        }
    }

    @Override
    public Type visitMethodCall(MethodCall node) {
        Type receiverType = node.getReceiver().accept(this);

        if (!(receiverType instanceof ClassicalType)) {
            errors.report("Method call receiver must be a classical type",
                    node.getReceiver().getPosition());
            return currentEnv.getErrorType();
        }

        MethodDeclaration method = lookupMethod(receiverType, node.getMethodName());
        if (method == null) {
            errors.report("Method not found: " + node.getMethodName(), node.getPosition());
            return currentEnv.getErrorType();
        }

        List<Parameter> params = method.getParameters();
        List<Expression> args = node.getArguments();

        if (params.size() != args.size()) {
            errors.report("Wrong number of arguments", node.getPosition());
            return currentEnv.getErrorType();
        }

        for (int i = 0; i < params.size(); i++) {
            Type paramType = params.get(i).getType();
            Type argType = args.get(i).accept(this);
            if (!isAssignable(paramType, argType)) {
                errors.report("Argument type mismatch", args.get(i).getPosition());
            }
        }

        return method.getReturnType();
    }

    @Override
    public Type visitQuantumGateApplication(QuantumGateApplication node) {
        if (!inQuantumContext) {
            errors.report("Quantum gates can only be applied within quantum blocks",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        for (QubitExpression target : node.getTargets()) {
            Type targetType = target.accept(this);
            if (!(targetType instanceof QuantumType) ||
                    ((QuantumType) targetType).getKind() != QuantumTypeKind.QUBIT) {
                errors.report("Gate target must be a qubit", target.getPosition());
            }
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitQuantumMeasurement(QuantumMeasurement node) {
        if (!inQuantumContext) {
            errors.report("Quantum measurement can only be performed within quantum blocks",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        Type targetType = node.getTarget().accept(this);
        if (!(targetType instanceof QuantumType)) {
            errors.report("Measurement target must be a quantum type", node.getPosition());
            return currentEnv.getErrorType();
        }

        return node.getMeasurementType();
    }

    // Helper methods
    private boolean isNumeric(Type type) {
        return type instanceof ClassicalType && ((ClassicalType) type).isNumeric();
    }

    private boolean isIntegral(Type type) {
        return type instanceof ClassicalType && ((ClassicalType) type).isIntegral();
    }

    private boolean isBoolean(Type type) {
        return type instanceof ClassicalType && ((ClassicalType) type).isBoolean();
    }

    private boolean isOrdered(Type type) {
        return type instanceof ClassicalType && ((ClassicalType) type).isOrdered();
    }

    private boolean isComparable(Type t1, Type t2) {
        if (t1 instanceof ClassicalType && t2 instanceof ClassicalType) {
            return ((ClassicalType) t1).isComparableTo((ClassicalType) t2);
        }
        return false;
    }

    private boolean isAssignable(Type target, Type source) {
        if (target.equals(source)) return true;
        if (target instanceof ClassicalType && source instanceof ClassicalType) {
            return ((ClassicalType) target).isAssignableFrom((ClassicalType) source);
        }
        if (target instanceof QuantumType qt1 && source instanceof QuantumType qt2) {
            return qt1.getKind() == qt2.getKind();
        }
        return false;
    }

    private Type promoteNumeric(Type t1, Type t2) {
        if (!(t1 instanceof ClassicalType) || !(t2 instanceof ClassicalType)) {
            return currentEnv.getErrorType();
        }
        return ((ClassicalType) t1).promoteWith((ClassicalType) t2);
    }


    private MethodDeclaration lookupMethod(Type receiverType, String methodName) {
        if (!(receiverType instanceof ClassType classType)) {
            return null;
        }
        return classType.getMethods().stream()
                .filter(m -> m.getName().equals(methodName))
                .findFirst()
                .orElse(null);
    }

    // Remaining visit methods
    @Override
    public Type visitArrayAccess(ArrayAccess node) {
        Type arrayType = node.getArray().accept(this);
        Type indexType = node.getIndex().accept(this);

        if (!(arrayType instanceof ArrayType)) {
            errors.report("Array access requires array type", node.getArray().getPosition());
            return currentEnv.getErrorType();
        }

        if (!isIntegral(indexType)) {
            errors.report("Array index must be integral type", node.getIndex().getPosition());
            return currentEnv.getErrorType();
        }

        return ((ArrayType) arrayType).getElementType();
    }

    @Override
    public Type visitArrayInitializer(ArrayInitializer node) {
        if (node.getElements().isEmpty()) {
            return new ArrayType(node.getPosition(), List.of(), currentEnv.getObjectType(), 1);
        }

        Type elementType = node.getElements().get(0).accept(this);
        for (int i = 1; i < node.getElements().size(); i++) {
            Type nextType = node.getElements().get(i).accept(this);
            if (!isAssignable(elementType, nextType)) {
                errors.report("Inconsistent element types in array initializer",
                        node.getElements().get(i).getPosition());
                return currentEnv.getErrorType();
            }
        }

        return new ArrayType(node.getPosition(), List.of(), elementType, 1);
    }

    @Override
    public Type visitAssignment(Assignment node) {
        Type targetType = node.getTarget().accept(this);
        Type valueType = node.getValue().accept(this);

        if (!isAssignable(targetType, valueType)) {
            errors.report("Cannot assign value of type " + valueType + " to target of type " + targetType,
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        // Handle compound assignments
        if (node.getOperator() != AssignmentOperator.ASSIGN) {
            switch (node.getOperator()) {
                case ADD_ASSIGN, SUBTRACT_ASSIGN, MULTIPLY_ASSIGN, DIVIDE_ASSIGN, MODULO_ASSIGN -> {
                    if (!isNumeric(targetType) || !isNumeric(valueType)) {
                        errors.report("Arithmetic compound assignment requires numeric types",
                                node.getPosition());
                        return currentEnv.getErrorType();
                    }
                }
                case AND_ASSIGN, OR_ASSIGN, XOR_ASSIGN -> {
                    if (!isIntegral(targetType) || !isIntegral(valueType)) {
                        errors.report("Bitwise compound assignment requires integral types",
                                node.getPosition());
                        return currentEnv.getErrorType();
                    }
                }
            }
        }

        return targetType;
    }

    @Override
    public Type visitCast(CastExpression node) {
        Type targetType = node.getType().accept(this);
        Type sourceType = node.getExpression().accept(this);

        // Check if cast is valid
        if (!isCastable(sourceType, targetType)) {
            errors.report("Invalid cast from " + sourceType + " to " + targetType,
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        return targetType;
    }

    private boolean isCastable(Type source, Type target) {
        if (isAssignable(target, source)) return true;
        if (source instanceof ClassicalType cs && target instanceof ClassicalType ct) {
            return cs.isNumeric() && ct.isNumeric();
        }
        return false;
    }

    @Override
    public Type visitTernary(TernaryExpression node) {
        Type condType = node.getCondition().accept(this);
        if (!isBoolean(condType)) {
            errors.report("Ternary condition must be boolean", node.getCondition().getPosition());
            return currentEnv.getErrorType();
        }

        Type thenType = node.getThenExpression().accept(this);
        Type elseType = node.getElseExpression().accept(this);

        if (isAssignable(thenType, elseType)) {
            return thenType;
        }
        if (isAssignable(elseType, thenType)) {
            return elseType;
        }

        errors.report("Incompatible types in ternary expression", node.getPosition());
        return currentEnv.getErrorType();
    }

    @Override
    public Type visitLambda(LambdaExpression node) {
        enterScope("lambda" + scopeStack.size());

        // Process parameters
        for (Parameter param : node.getParameters()) {
            Type paramType = param.getType().accept(this);
            currentEnv.define(param.getName(), paramType);
        }

        // Check body
        Type bodyType = node.getBody().accept(this);

        exitScope();
        return currentEnv.getFunctionalInterfaceType(node.getParameters(), bodyType);
    }

    @Override
    public Type visitForStatement(ForStatement node) {
        enterScope("for" + scopeStack.size());

        if (node.getInitialization() != null) {
            node.getInitialization().accept(this);
        }

        if (node.getCondition() != null) {
            Type condType = node.getCondition().accept(this);
            if (!isBoolean(condType)) {
                errors.report("For loop condition must be boolean",
                        node.getCondition().getPosition());
            }
        }

        if (node.getUpdate() != null) {
            node.getUpdate().accept(this);
        }

        node.getBody().accept(this);

        exitScope();
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitDoWhileStatement(DoWhileStatement node) {
        node.getBody().accept(this);

        Type condType = node.getCondition().accept(this);
        if (!isBoolean(condType)) {
            errors.report("Do-while condition must be boolean",
                    node.getCondition().getPosition());
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitTryStatement(TryStatement node) {
        node.getTryBlock().accept(this);

        for (CatchClause catchClause : node.getCatchClauses()) {
            Type exceptionType = catchClause.getExceptionType().accept(this);
            if (!isAssignable(currentEnv.getThrowableType(), exceptionType)) {
                errors.report("Catch clause type must be Throwable",
                        catchClause.getPosition());
            }
            catchClause.getBody().accept(this);
        }

        if (node.getFinallyBlock() != null) {
            node.getFinallyBlock().accept(this);
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitQuantumStatePreparation(QuantumStatePreparation node) {
        if (!inQuantumContext) {
            errors.report("Quantum state preparation must be in quantum context",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        Type targetType = node.getTarget().accept(this);
        if (!(targetType instanceof QuantumType) ||
                ((QuantumType) targetType).getKind() != QuantumTypeKind.QUBIT) {
            errors.report("State preparation target must be a qubit",
                    node.getTarget().getPosition());
            return currentEnv.getErrorType();
        }

        Type stateType = node.getState().accept(this);
        if (!(stateType instanceof QuantumType) ||
                ((QuantumType) stateType).getKind() != QuantumTypeKind.STATE) {
            errors.report("Invalid quantum state expression",
                    node.getState().getPosition());
            return currentEnv.getErrorType();
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitQuantumIfStatement(QuantumIfStatement node) {
        if (!inQuantumContext) {
            errors.report("Quantum if statement must be in quantum context",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        Type condType = node.getCondition().accept(this);
        if (!(condType instanceof QuantumType) ||
                ((QuantumType) condType).getKind() != QuantumTypeKind.QUBIT) {
            errors.report("Quantum if condition must be a qubit",
                    node.getCondition().getPosition());
        }

        node.getThenBlock().accept(this);
        if (node.getElseBlock() != null) {
            node.getElseBlock().accept(this);
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitQuantumWhileStatement(QuantumWhileStatement node) {
        if (!inQuantumContext) {
            errors.report("Quantum while statement must be in quantum context",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        Type condType = node.getCondition().accept(this);
        if (!(condType instanceof QuantumType) ||
                ((QuantumType) condType).getKind() != QuantumTypeKind.QUBIT) {
            errors.report("Quantum while condition must be a qubit",
                    node.getCondition().getPosition());
        }

        node.getBody().accept(this);

        Type terminationType = node.getTermination().accept(this);
        if (!isBoolean(terminationType)) {
            errors.report("Quantum while termination condition must be boolean",
                    node.getTermination().getPosition());
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitCleanBlock(CleanBlock node) {
        boolean prevCleanBlock = inCleanBlock;
        inCleanBlock = true;

        for (QubitExpression qubit : node.getQubits()) {
            Type qubitType = qubit.accept(this);
            if (!(qubitType instanceof QuantumType) ||
                    ((QuantumType) qubitType).getKind() != QuantumTypeKind.QUBIT) {
                errors.report("Clean block can only contain qubits",
                        qubit.getPosition());
            }
        }

        inCleanBlock = prevCleanBlock;
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitUncomputeBlock(UncomputeBlock node) {
        if (!inQuantumContext) {
            errors.report("Uncompute block must be in quantum context",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        node.getBody().accept(this);
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitAllocationStatement(AllocationStatement node) {
        Type targetType = node.getTarget().accept(this);
        Type sizeType = node.getSize().accept(this);

        if (!isIntegral(sizeType)) {
            errors.report("Allocation size must be an integral type",
                    node.getSize().getPosition());
        }

        if (!(targetType instanceof ArrayType || targetType instanceof QuantumType)) {
            errors.report("Allocation target must be array or quantum type",
                    node.getTarget().getPosition());
            return currentEnv.getErrorType();
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitDeallocationStatement(DeallocationStatement node) {
        Type targetType = node.getTarget().accept(this);

        if (!(targetType instanceof ArrayType || targetType instanceof QuantumType)) {
            errors.report("Deallocation target must be array or quantum type",
                    node.getTarget().getPosition());
            return currentEnv.getErrorType();
        }

        return currentEnv.getUnitType();
    }

    @Override
    public Type visitGarbageCollection(GarbageCollectionStatement node) {
        // No specific type checking needed
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitQuantumToClassical(QuantumToClassicalConversion quantumToClassicalConversion) {
        return null;
    }

    @Override
    public Type visitHybridWhileStatement(HybridWhileStatement hybridWhileStatement) {
        return null;
    }

    @Override
    public Type visitHybridIfStatement(HybridIfStatement hybridIfStatement) {
        return null;
    }

    @Override
    public Type visitHybridBlock(HybridBlock hybridBlock) {
        return null;
    }

    @Override
    public Type visitClassicalToQuantum(ClassicalToQuantumConversion classicalToQuantumConversion) {
        return null;
    }

    @Override
    public Type visitThrowStatement(ThrowStatement throwStatement) {
        return null;
    }

    @Override
    public Type visitSynchronizedStatement(SynchronizedStatement synchronizedStatement) {
        return null;
    }

    @Override
    public Type visitReturnStatement(ReturnStatement returnStatement) {
        return null;
    }

    @Override
    public Type visitExpressionStatement(ExpressionStatement expressionStatement) {
        return null;
    }

    @Override
    public Type visitContinueStatement(ContinueStatement continueStatement) {
        return null;
    }

    @Override
    public Type visitBreakStatement(BreakStatement breakStatement) {
        return null;
    }

    @Override
    public Type visitAssertStatement(AssertStatement assertStatement) {
        return null;
    }

    @Override
    public Type visitQubitReference(QubitReference node) {
        Type type = currentEnv.lookup(node.getIdentifier());
        if (type == null) {
            errors.report("Undefined qubit: " + node.getIdentifier(),
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        if (!(type instanceof QuantumType) ||
                ((QuantumType) type).getKind() != QuantumTypeKind.QUBIT) {
            errors.report("Variable is not a qubit: " + node.getIdentifier(),
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        return type;
    }

    @Override
    public Type visitTensorProduct(TensorProduct node) {
        int totalQubits = 0;
        for (QubitExpression factor : node.getFactors()) {
            Type factorType = factor.accept(this);
            if (!(factorType instanceof QuantumType qType)) {
                errors.report("Tensor product factor must be quantum type",
                        factor.getPosition());
                return currentEnv.getErrorType();
            }

            if (qType.getKind() == QuantumTypeKind.QUBIT) {
                totalQubits += 1;
            } else if (qType.getKind() == QuantumTypeKind.QUREG) {
                totalQubits += qType.getSize();
            } else {
                errors.report("Invalid quantum type in tensor product",
                        factor.getPosition());
                return currentEnv.getErrorType();
            }
        }

        return new QuantumType(node.getPosition(), List.of(),
                QuantumTypeKind.QUREG, totalQubits);
    }

    @Override
    public Type visitStateExpression(StateExpression node) {
        int numQubits = node.getNumQubits();
        int expectedDimension = 1 << numQubits;

        if (node.getCoefficients().size() != expectedDimension) {
            errors.report("State vector size doesn't match number of qubits",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        // Check that coefficients sum to 1 (approximately)
        double sumSquared = 0.0;
        for (ComplexNumber coeff : node.getCoefficients()) {
            sumSquared += coeff.magnitudeSquared();
        }
        if (Math.abs(sumSquared - 1.0) > 1e-10) {
            errors.report("State vector coefficients must have unit norm",
                    node.getPosition());
        }

        return new QuantumType(node.getPosition(), List.of(),
                QuantumTypeKind.STATE, numQubits);
    }

    @Override
    public Type visitQuantumRegisterAccess(QuantumRegisterAccess node) {
        Type registerType = node.getRegister().accept(this);
        if (!(registerType instanceof QuantumType) ||
                ((QuantumType) registerType).getKind() != QuantumTypeKind.QUREG) {
            errors.report("Register access requires quantum register type",
                    node.getRegister().getPosition());
            return currentEnv.getErrorType();
        }

        Type indexType = node.getIndex().accept(this);
        if (!isIntegral(indexType)) {
            errors.report("Register index must be integral type",
                    node.getIndex().getPosition());
            return currentEnv.getErrorType();
        }

        return new QuantumType(node.getPosition(), List.of(),
                QuantumTypeKind.QUBIT);
    }

    @Override
    public Type visitQuantumArrayType(QuantumArrayType quantumArrayType) {
        return null;
    }

    @Override
    public Type visitQuantumRegisterType(QuantumRegisterType quantumRegisterType) {
        return null;
    }

    @Override
    public Type visitQuantumArrayAccess(QuantumArrayAccess node) {
        Type arrayType = node.getArray().accept(this);
        if (!(arrayType instanceof ArrayType)) {
            errors.report("Array access requires array type",
                    node.getArray().getPosition());
            return currentEnv.getErrorType();
        }

        Type elementType = ((ArrayType) arrayType).getElementType();
        if (!(elementType instanceof QuantumType)) {
            errors.report("Array must contain quantum types",
                    node.getArray().getPosition());
            return currentEnv.getErrorType();
        }

        Type indexType = node.getIndex().accept(this);
        if (!isIntegral(indexType)) {
            errors.report("Array index must be integral type",
                    node.getIndex().getPosition());
            return currentEnv.getErrorType();
        }

        return elementType;
    }

    @Override
    public Type visitQuantumCastExpression(QuantumCastExpression node) {
        Type sourceType = node.getExpression().accept(this);
        Type targetType = node.getTargetType();

        if (!(sourceType instanceof QuantumType qSource) ||
                !(targetType instanceof QuantumType qTarget)) {
            errors.report("Quantum cast requires quantum types",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        // Check valid quantum type conversions
        if (!isValidQuantumCast(qSource, qTarget)) {
            errors.report("Invalid quantum type cast from " + qSource + " to " + qTarget,
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        return targetType;
    }

    @Override
    public Type visitQuantumCircuit(QuantumCircuit quantumCircuit) {
        return null;
    }

    @Override
    public Type visitEntanglementOperation(EntanglementOperation entanglementOperation) {
        return null;
    }

    @Override
    public Type visitQuantumFunction(QuantumFunction quantumFunction) {
        return null;
    }

    @Override
    public Type visitQuantumOracle(QuantumOracle quantumOracle) {
        return null;
    }

    @Override
    public Type visitQuantumTeleport(QuantumTeleport quantumTeleport) {
        return null;
    }

    @Override
    public Type visitQuantumForStatement(QuantumForStatement quantumForStatement) {
        return null;
    }

    @Override
    public Type visitQuantumAncillaDeclaration(QuantumAncillaDeclaration quantumAncillaDeclaration) {
        return null;
    }

    @Override
    public Type visitQuantumRegisterDeclaration(QuantumRegisterDeclaration quantumRegisterDeclaration) {
        return null;
    }

    @Override
    public Type visitQuantumBarrier(QuantumBarrier quantumBarrier) {
        return null;
    }

    private boolean isValidQuantumCast(QuantumType source, QuantumType target) {
        // Define valid quantum type conversions
        switch (source.getKind()) {
            case QUBIT:
                return target.getKind() == QuantumTypeKind.STATE;
            case QUREG:
                return target.getKind() == QuantumTypeKind.STATE &&
                        source.getSize() == target.getSize();
            case STATE:
                return (target.getKind() == QuantumTypeKind.QUREG &&
                        source.getSize() == target.getSize()) ||
                        (target.getKind() == QuantumTypeKind.QUBIT &&
                                source.getSize() == 1);
            default:
                return false;
        }
    }

    @Override
    public Type visitConstructorDeclaration(ConstructorDeclaration node) {
        enterScope(node.getName() + "$constructor");

        // Check parameters
        for (Parameter param : node.getParameters()) {
            Type paramType = param.getType().accept(this);
            currentEnv.define(param.getName(), paramType);
        }

        // Check constructor body
        if (node.getBody() != null) {
            node.getBody().accept(this);
        }

        exitScope();
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitFieldDeclaration(FieldDeclaration node) {
        Type fieldType = node.getType().accept(this);

        if (node.getInitializer() != null) {
            Type initType = node.getInitializer().accept(this);
            if (!isAssignable(fieldType, initType)) {
                errors.report("Cannot initialize field of type " + fieldType +
                                " with expression of type " + initType,
                        node.getInitializer().getPosition());
            }
        }

        currentEnv.define(node.getName(), fieldType);
        return fieldType;
    }

    @Override
    public Type visitPackageDeclaration(PackageDeclaration node) {
        // No type checking needed for package declarations
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitImportDeclaration(ImportDeclaration node) {
        // Import declarations are handled during symbol resolution
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitCatchClause(CatchClause node) {
        enterScope("catch" + scopeStack.size());

        Type exceptionType = node.getExceptionType().accept(this);
        currentEnv.define(node.getParameter(), exceptionType);

        Type bodyType = node.getBody().accept(this);

        exitScope();
        return bodyType;
    }

    @Override
    public Type visitPrimitiveType(PrimitiveType node) {
        return node;
    }

    @Override
    public Type visitClassType(ClassType node) {
        // Verify type arguments if present
        for (Type typeArg : node.getTypeArguments()) {
            typeArg.accept(this);
        }
        return node;
    }

    @Override
    public Type visitArrayType(ArrayType node) {
        node.getElementType().accept(this);
        return node;
    }

    @Override
    public Type visitTypeParameter(TypeParameter node) {
        if (!node.getBounds().isEmpty()) {
            // Check each bound for validity
            for (Type boundType : node.getBounds()) {
                Type checkedBound = boundType.accept(this);

                // Ensure bound is a class or interface type
                if (!(checkedBound instanceof ClassicalType classicalBound)) {
                    errors.report("Type parameter bound must be a classical type",
                            boundType.getPosition());
                    continue;
                }

                // Verify bound is not a final class if it's a class bound
                if (classicalBound instanceof ClassType classBound) {
                    if (!classBound.isInterface() &&
                            classBound.getModifiers().contains(Modifier.FINAL)) {
                        errors.report("Type parameter cannot have a final class as a bound",
                                boundType.getPosition());
                    }
                }

                // Check for primitive type bounds
                if (classicalBound.isPrimitive()) {
                    errors.report("Type parameter bound cannot be a primitive type",
                            boundType.getPosition());
                }

                // Verify array bounds
                if (classicalBound instanceof ArrayType) {
                    errors.report("Type parameter bound cannot be an array type",
                            boundType.getPosition());
                }
            }
        }

        // Return the type parameter itself
        return node;
    }

    @Override
    public Type visitWildcardType(WildcardType node) {
        if (node.getBound() != null) {
            node.getBound().accept(this);
        }
        return node;
    }

    @Override
    public Type visitDocumentation(Documentation node) {
        // No type checking needed for documentation
        return currentEnv.getUnitType();
    }

    @Override
    public Type visitErrorNode(ErrorNode errorNode) {
        return null;
    }

    @Override
    public Type visitComment(CommentNode commentNode) {
        return null;
    }

    // Helper methods for quantum-specific validation
    private boolean isValidQuantumContext() {
        return inQuantumContext && !inCleanBlock;
    }

    private void requireQuantumContext(Node node) {
        if (!isValidQuantumContext()) {
            errors.report("Operation requires quantum context", node.getPosition());
        }
    }

    private void forbidQuantumOperation(Node node) {
        if (inQuantumContext) {
            errors.report("Operation not allowed in quantum context", node.getPosition());
        }
    }

    @Override
    public Type visitUnaryExpression(UnaryExpression node) {
        Type operandType = node.getOperand().accept(this);

        switch (node.getOperator()) {
            case PLUS, MINUS -> {
                if (!isNumeric(operandType)) {
                    errors.report("Unary +/- requires numeric operand",
                            node.getPosition());
                    return currentEnv.getErrorType();
                }
                return operandType;
            }
            case NOT -> {
                if (!isBoolean(operandType)) {
                    errors.report("Logical NOT requires boolean operand",
                            node.getPosition());
                    return currentEnv.getErrorType();
                }
                return currentEnv.getBooleanType();
            }
            case BITWISE_COMPLEMENT -> {
                if (!isIntegral(operandType)) {
                    errors.report("Bitwise complement requires integral operand",
                            node.getPosition());
                    return currentEnv.getErrorType();
                }
                return operandType;
            }
            case INCREMENT, DECREMENT -> {
                if (!isNumeric(operandType)) {
                    errors.report("Increment/decrement requires numeric operand",
                            node.getPosition());
                    return currentEnv.getErrorType();
                }
                // Check if operand is a valid lvalue
                if (!isLValue(node.getOperand())) {
                    errors.report("Increment/decrement requires variable, array element, or field",
                            node.getOperand().getPosition());
                    return currentEnv.getErrorType();
                }
                return operandType;
            }
            default -> {
                errors.report("Unsupported unary operator: " + node.getOperator(),
                        node.getPosition());
                return currentEnv.getErrorType();
            }
        }
    }

    @Override
    public Type visitLiteralExpression(LiteralExpression node) {
        return switch (node.getLiteralType()) {
            case INTEGER -> {
                Object value = node.getValue();
                if (value instanceof Long) {
                    yield currentEnv.getLongType();
                } else {
                    yield currentEnv.getIntType();
                }
            }
            case FLOAT -> {
                Object value = node.getValue();
                if (value instanceof Double) {
                    yield currentEnv.getDoubleType();
                } else {
                    yield currentEnv.getFloatType();
                }
            }
            case BOOLEAN -> currentEnv.getBooleanType();
            case CHAR -> currentEnv.getCharType();
            case STRING -> currentEnv.getStringType();
            case NULL -> currentEnv.getNullType();
            default -> {
                errors.report("Unknown literal type: " + node.getLiteralType(),
                        node.getPosition());
                yield currentEnv.getErrorType();
            }
        };
    }

    @Override
    public Type visitVariableReference(VariableReference node) {
        Type type = currentEnv.lookup(node.getName());
        if (type == null) {
            errors.report("Undefined variable: " + node.getName(),
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        // Check quantum context restrictions
        if (type instanceof QuantumType && !isValidQuantumContext()) {
            errors.report("Cannot access quantum variable outside quantum context",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        return type;
    }

    @Override
    public Type visitInstanceOf(InstanceOfExpression node) {
        // Check the expression being tested
        Type expressionType = node.getExpression().accept(this);
        Type testType = node.getType().accept(this);

        // Verify the types involved are reference types
        if (expressionType instanceof PrimitiveType) {
            errors.report("Cannot use instanceof on primitive type",
                    node.getExpression().getPosition());
            return currentEnv.getErrorType();
        }

        if (testType instanceof PrimitiveType) {
            errors.report("Cannot test instanceof against primitive type",
                    node.getType().getPosition());
            return currentEnv.getErrorType();
        }

        // Check if the expression is a final class
        if (expressionType instanceof ClassType exprClass) {
            if (exprClass.getModifiers().contains(Modifier.FINAL)) {
                // For final classes, we can statically determine if the instanceof will always be true or false
                if (testType instanceof ClassType testClass) {
                    if (!couldBeInstance(exprClass, testClass)) {
                        errors.report("Expression of type " + exprClass +
                                        " will never be an instance of " + testClass,
                                node.getPosition());
                    }
                }
            }
        }

        // Check if the test type is a final class
        if (testType instanceof ClassType testClass) {
            if (testClass.getModifiers().contains(Modifier.FINAL)) {
                // For final test types, verify compatibility
                if (expressionType instanceof ClassType exprClass) {
                    if (!couldBeInstance(exprClass, testClass)) {
                        errors.report("Expression of type " + exprClass +
                                        " cannot be an instance of final class " + testClass,
                                node.getPosition());
                    }
                }
            }
        }

        // Check for array types
        if (expressionType instanceof ArrayType exprArray && testType instanceof ArrayType testArray) {

            // Array types must have compatible element types
            if (!couldBeInstance(exprArray.getElementType(), testArray.getElementType())) {
                errors.report("Array types are incompatible for instanceof check",
                        node.getPosition());
            }
        }

        // Check for interface types
        if (testType instanceof ClassType && ((ClassType) testType).isInterface()) {
            // Any reference type could potentially implement an interface
            // No additional checks needed
        }

        // Instanceof always returns boolean
        return currentEnv.getBooleanType();
    }

    /**
     * Determines if there's any possibility that an object of type sub could be an instance of type sup
     */
    private boolean couldBeInstance(Type sub, Type sup) {
        if (sub.equals(sup)) {
            return true;
        }

        // Handle class types
        if (sub instanceof ClassType subClass && sup instanceof ClassType supClass) {

            // Check class hierarchy
            if (isInHierarchy(subClass, supClass)) {
                return true;
            }

            // Check interfaces
            if (supClass.isInterface()) {
                return couldImplementInterface(subClass, supClass);
            }

            // If neither is final, there could be an unexamined subclass relationship
            if (!subClass.getModifiers().contains(Modifier.FINAL) &&
                    !supClass.getModifiers().contains(Modifier.FINAL)) {
                return true;
            }
        }

        // Handle array types
        if (sub instanceof ArrayType subArray && sup instanceof ArrayType supArray) {

            // Array types must have same number of dimensions
            if (subArray.getDimensions() != supArray.getDimensions()) {
                return false;
            }

            // Check element types
            return couldBeInstance(subArray.getElementType(), supArray.getElementType());
        }

        return false;
    }

    /**
     * Checks if sub is in the class hierarchy of sup
     */
    private boolean isInHierarchy(ClassType sub, ClassType sup) {
        if (sub.equals(sup)) {
            return true;
        }

        // Check superclass chain
        ClassType current = sub;
        while (current.getSupertype() != null) {
            if (current.getSupertype().equals(sup)) {
                return true;
            }
            current = current.getSupertype();
        }

        return false;
    }

    /**
     * Checks if a class could potentially implement an interface
     */
    private boolean couldImplementInterface(ClassType type, ClassType iface) {
        if (!iface.isInterface()) {
            return false;
        }

        // Check directly implemented interfaces
        for (ClassType implemented : type.getInterfaces()) {
            if (implemented.equals(iface)) {
                return true;
            }
            // Check super-interfaces
            if (couldImplementInterface(implemented, iface)) {
                return true;
            }
        }

        // Check interfaces from superclass
        if (type.getSupertype() != null) {
            return couldImplementInterface(type.getSupertype(), iface);
        }

        // If not final, could have unexamined implementations
        return !type.getModifiers().contains(Modifier.FINAL);
    }


    @Override
    public Type visitMethodReference(MethodReferenceExpression node) {
        Type qualifierType = node.getQualifier().accept(this);

        // Handle different forms of method references
        if (qualifierType instanceof ClassType) {
            // Class::staticMethod or Class::new
            if (node.getMethodName().equals("new")) {
                // Verify the class has an appropriate constructor
                verifyConstructorReference((ClassType) qualifierType, node);
            } else {
                // Verify the class has an appropriate static method
                verifyStaticMethodReference((ClassType) qualifierType, node);
            }
        } else {
            // instance::method
            verifyInstanceMethodReference(qualifierType, node);
        }

        // Return a functional interface type based on the reference
        return inferFunctionalInterfaceType(qualifierType, node);
    }

    @Override
    public Type visitArrayCreation(ArrayCreationExpression node) {
        Type elementType = node.getElementType().accept(this);

        // Check dimension expressions
        for (Expression dimExpr : node.getDimensions()) {
            Type dimType = dimExpr.accept(this);
            if (!isIntegral(dimType)) {
                errors.report("Array dimension must be integral type",
                        dimExpr.getPosition());
            }
        }

        // Check array initializer if present
        if (node.getInitializer() != null) {
            Type initType = node.getInitializer().accept(this);
            if (!isAssignable(new ArrayType(node.getPosition(), List.of(), elementType, 1), initType)) {
                errors.report("Array initializer type mismatch",
                        node.getInitializer().getPosition());
            }
        }

        // Create array type with appropriate number of dimensions
        return new ArrayType(
                node.getPosition(),
                node.getAnnotations(),
                elementType,
                node.getDimensions().size()
        );
    }

    @Override
    public Type visitObjectCreation(ObjectCreationExpression node) {
        Type type = node.getType().accept(this);

        if (!(type instanceof ClassType classType)) {
            errors.report("Cannot create instance of non-class type",
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        // Check constructor arguments
        List<Type> argTypes = new ArrayList<>();
        for (Expression arg : node.getArguments()) {
            argTypes.add(arg.accept(this));
        }

        // Find matching constructor
        boolean constructorFound = false;
        for (ConstructorDeclaration constructor : findConstructors(classType)) {
            if (matchesParameters(constructor.getParameters(), argTypes)) {
                constructorFound = true;
                break;
            }
        }

        if (!constructorFound) {
            errors.report("No matching constructor found for " + classType,
                    node.getPosition());
            return currentEnv.getErrorType();
        }

        // Handle anonymous class if present
        if (node.getAnonymousClass() != null) {
            enterScope("anonymous" + scopeStack.size());
            node.getAnonymousClass().accept(this);
            exitScope();
        }

        return type;
    }

    // Helper methods for the above implementations
    private boolean isLValue(Expression expr) {
        return expr instanceof VariableReference ||
                expr instanceof ArrayAccess ||
                expr instanceof MethodCall;  // For cases like obj.getField()
    }

    private boolean couldBeInstance(ClassType exprType, ClassType testType) {
        // Check if there's any possibility of assignment compatibility
        if (isAssignable(testType, exprType) || isAssignable(exprType, testType)) {
            return true;
        }
        // Check for interface implementation
        return testType.isInterface() || exprType.isInterface();
    }

    private void verifyConstructorReference(ClassType classType, MethodReferenceExpression node) {
        // Verify the class has at least one accessible constructor
        boolean hasAccessibleConstructor = false;
        for (ConstructorDeclaration constructor : findConstructors(classType)) {
            if (isAccessible(constructor)) {
                hasAccessibleConstructor = true;
                break;
            }
        }
        if (!hasAccessibleConstructor) {
            errors.report("No accessible constructor found in " + classType,
                    node.getPosition());
        }
    }

    private void verifyStaticMethodReference(ClassType classType, MethodReferenceExpression node) {
        // Verify the class has the referenced static method
        boolean hasMethod = false;
        for (MethodDeclaration method : findMethods(classType, node.getMethodName())) {
            if (isStatic(method) && isAccessible(method)) {
                hasMethod = true;
                break;
            }
        }
        if (!hasMethod) {
            errors.report("No accessible static method " + node.getMethodName() + " found in " + classType,
                    node.getPosition());
        }
    }

    private void verifyInstanceMethodReference(Type qualifierType, MethodReferenceExpression node) {
        // Verify the type has the referenced instance method
        boolean hasMethod = false;
        if (qualifierType instanceof ClassType) {
            for (MethodDeclaration method : findMethods((ClassType) qualifierType, node.getMethodName())) {
                if (!isStatic(method) && isAccessible(method)) {
                    hasMethod = true;
                    break;
                }
            }
            if (!hasMethod) {
                errors.report("No accessible instance method " + node.getMethodName() + " found in " + qualifierType,
                        node.getPosition());
            }
        } else {
            errors.report("Cannot reference methods on non-class type " + qualifierType,
                    node.getPosition());
        }
    }

    private Type inferFunctionalInterfaceType(Type qualifierType, MethodReferenceExpression node) {
        // This would involve complex type inference based on context
        // For now, we return a generic functional interface type
        return currentEnv.getFunctionalInterfaceType(List.of(), currentEnv.getObjectType());
    }

    private List<ConstructorDeclaration> findConstructors(ClassType classType) {
        // This would need to be implemented based on how constructors are stored
        return new ArrayList<>(); // Placeholder
    }

    private List<MethodDeclaration> findMethods(ClassType classType, String methodName) {
        // This would need to be implemented based on how methods are stored
        return new ArrayList<>(); // Placeholder
    }

    private boolean isAccessible(MethodDeclaration method) {
        // This would check visibility modifiers
        return true; // Placeholder
    }

    private boolean isAccessible(ConstructorDeclaration constructor) {
        // This would check visibility modifiers
        return true; // Placeholder
    }

    private boolean isStatic(MethodDeclaration method) {
        return method.getModifiers().contains(Modifier.STATIC);
    }

    private boolean matchesParameters(List<Parameter> params, List<Type> argTypes) {
        if (params.size() != argTypes.size()) return false;

        for (int i = 0; i < params.size(); i++) {
            if (!isAssignable(params.get(i).getType(), argTypes.get(i))) {
                return false;
            }
        }

        return true;
    }
}