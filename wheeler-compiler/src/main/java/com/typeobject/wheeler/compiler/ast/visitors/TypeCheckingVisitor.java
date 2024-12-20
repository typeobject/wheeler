package com.typeobject.wheeler.compiler.ast.visitors;

import com.typeobject.wheeler.compiler.ErrorReporter;
import com.typeobject.wheeler.compiler.analysis.TypeEnvironment;
import com.typeobject.wheeler.compiler.ast.CommentNode;
import com.typeobject.wheeler.compiler.ast.CompilationUnit;
import com.typeobject.wheeler.compiler.ast.Documentation;
import com.typeobject.wheeler.compiler.ast.ErrorNode;
import com.typeobject.wheeler.compiler.ast.ImportDeclaration;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Expression;
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
import com.typeobject.wheeler.compiler.ast.quantum.gates.QuantumGate;
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
import java.util.List;

public class TypeCheckingVisitor implements NodeVisitor<Type> {
    private final TypeEnvironment env;
    private final ErrorReporter errors;

    public TypeCheckingVisitor(TypeEnvironment env, ErrorReporter errors) {
        this.env = env;
        this.errors = errors;
    }

    @Override
    public Type visitDocumentation(Documentation node) {
        return null;
    }

    @Override
    public Type visitErrorNode(ErrorNode errorNode) {
        return null;
    }

    @Override
    public Type visitComment(CommentNode commentNode) {
        return null;
    }

    // Top-level declarations
    @Override
    public Type visitCompilationUnit(CompilationUnit node) {
        for (Declaration decl : node.getDeclarations()) {
            decl.accept(this);
        }
        return env.getUnitType();
    }

    @Override
    public Type visitImportDeclaration(ImportDeclaration node) {
        return null;
    }

    @Override
    public Type visitPackageDeclaration(PackageDeclaration node) {
        return null;
    }

    @Override
    public Type visitClassDeclaration(ClassDeclaration node) {
        // Create new scope for class members
        TypeEnvironment classEnv = new TypeEnvironment(env, env.getUnitType());

        // Check superclass if present
        if (node.getSuperClass() != null) {
            Type superType = node.getSuperClass().accept(this);
            if (!(superType instanceof ClassicalType)) {
                errors.report("Superclass must be a classical type", node.getSuperClass().getPosition());
            }
        }

        // Check each method
        for (Declaration member : node.getMembers()) {
            member.accept(this);
        }

        return env.getUnitType();
    }

    @Override
    public Type visitMethodDeclaration(MethodDeclaration node) {
        // Create new scope for method body
        TypeEnvironment methodEnv = new TypeEnvironment(env, env.getUnitType());

        // Check return type
        Type returnType = node.getReturnType().accept(this);

        // Add parameters to scope
        for (Parameter param : node.getParameters()) {
            Type paramType = param.getType().accept(this);
            methodEnv.define(param.getName(), paramType);
        }

        // Check method body
        if (node.getBody() != null) {
            Type bodyType = node.getBody().accept(this);

            // Verify return type compatibility
            if (!isAssignable(returnType, bodyType)) {
                errors.report("Method body type incompatible with declared return type",
                        node.getBody().getPosition());
            }
        }

        return env.getUnitType();
    }

    @Override
    public Type visitConstructorDeclaration(ConstructorDeclaration node) {
        return null;
    }

    @Override
    public Type visitFieldDeclaration(FieldDeclaration node) {
        return null;
    }

    @Override
    public Type visitBlock(Block node) {
        return null;
    }

    @Override
    public Type visitIfStatement(IfStatement node) {
        return null;
    }

    @Override
    public Type visitWhileStatement(WhileStatement node) {
        return null;
    }

    @Override
    public Type visitForStatement(ForStatement node) {
        return null;
    }

    @Override
    public Type visitDoWhileStatement(DoWhileStatement node) {
        return null;
    }

    @Override
    public Type visitTryStatement(TryStatement node) {
        return null;
    }

    @Override
    public Type visitCatchClause(CatchClause node) {
        return null;
    }

    @Override
    public Type visitVariableDeclaration(VariableDeclaration node) {
        return null;
    }

    // Classical expressions
    @Override
    public Type visitBinaryExpression(BinaryExpression node) {
        Type leftType = node.getLeft().accept(this);
        Type rightType = node.getRight().accept(this);

        switch (node.getOperator()) {
            case ADD:
            case SUBTRACT:
            case MULTIPLY:
            case DIVIDE:
            case MODULO:
                if (!isNumeric(leftType) || !isNumeric(rightType)) {
                    errors.report("Arithmetic operators require numeric operands",
                            node.getPosition());
                    return env.getErrorType();
                }
                return promoteNumeric(leftType, rightType);

            case EQUAL:
            case NOT_EQUAL:
                if (!isComparable(leftType, rightType)) {
                    errors.report("Types are not comparable", node.getPosition());
                    return env.getErrorType();
                }
                return env.getBooleanType();

            case LESS_THAN:
            case LESS_EQUAL:
            case GREATER_THAN:
            case GREATER_EQUAL:
                if (!isOrdered(leftType) || !isOrdered(rightType)) {
                    errors.report("Comparison operators require ordered types",
                            node.getPosition());
                    return env.getErrorType();
                }
                return env.getBooleanType();

            case LOGICAL_AND:
            case LOGICAL_OR:
                if (!isBoolean(leftType) || !isBoolean(rightType)) {
                    errors.report("Logical operators require boolean operands",
                            node.getPosition());
                    return env.getErrorType();
                }
                return env.getBooleanType();

            default:
                errors.report("Unsupported binary operator: " + node.getOperator(),
                        node.getPosition());
                return env.getErrorType();
        }
    }

    @Override
    public Type visitUnaryExpression(UnaryExpression node) {
        Type operandType = node.getOperand().accept(this);

        switch (node.getOperator()) {
            case PLUS:
            case MINUS:
                if (!isNumeric(operandType)) {
                    errors.report("Unary +/- requires numeric operand", node.getPosition());
                    return env.getErrorType();
                }
                return operandType;

            case NOT:
                if (!isBoolean(operandType)) {
                    errors.report("Logical NOT requires boolean operand", node.getPosition());
                    return env.getErrorType();
                }
                return env.getBooleanType();

            case INCREMENT:
            case DECREMENT:
                if (!isNumeric(operandType)) {
                    errors.report("Increment/decrement requires numeric operand",
                            node.getPosition());
                    return env.getErrorType();
                }
                return operandType;

            default:
                errors.report("Unsupported unary operator: " + node.getOperator(),
                        node.getPosition());
                return env.getErrorType();
        }
    }

    @Override
    public Type visitLiteralExpression(LiteralExpression node) {
        switch (node.getLiteralType()) {
            case INTEGER:
                return env.getIntType();
            case FLOAT:
                return env.getFloatType();
            case DOUBLE:
                return env.getDoubleType();
            case BOOLEAN:
                return env.getBooleanType();
            case CHAR:
                return env.getCharType();
            case STRING:
                return env.getStringType();
            case NULL:
                return env.getNullType();
            default:
                errors.report("Unknown literal type", node.getPosition());
                return env.getErrorType();
        }
    }

    @Override
    public Type visitVariableReference(VariableReference node) {
        Type type = env.lookup(node.getName());
        if (type == null) {
            errors.report("Undefined variable: " + node.getName(), node.getPosition());
            return env.getErrorType();
        }
        return type;
    }

    @Override
    public Type visitInstanceOf(InstanceOfExpression node) {
        return null;
    }

    @Override
    public Type visitCast(CastExpression node) {
        return null;
    }

    @Override
    public Type visitTernary(TernaryExpression node) {
        return null;
    }

    @Override
    public Type visitLambda(LambdaExpression node) {
        return null;
    }

    @Override
    public Type visitMethodReference(MethodReferenceExpression node) {
        return null;
    }

    @Override
    public Type visitArrayCreation(ArrayCreationExpression node) {
        return null;
    }

    @Override
    public Type visitObjectCreation(ObjectCreationExpression node) {
        return null;
    }

    @Override
    public Type visitPrimitiveType(PrimitiveType node) {
        return null;
    }

    @Override
    public Type visitClassType(ClassType node) {
        return null;
    }

    @Override
    public Type visitArrayType(ArrayType node) {
        return null;
    }

    @Override
    public Type visitTypeParameter(TypeParameter node) {
        return null;
    }

    @Override
    public Type visitWildcardType(WildcardType node) {
        return null;
    }

    @Override
    public Type visitQuantumBlock(QuantumBlock node) {
        return null;
    }

    @Override
    public Type visitMethodCall(MethodCall node) {
        // Check receiver type
        Type receiverType = node.getReceiver().accept(this);
        if (!(receiverType instanceof ClassicalType)) {
            errors.report("Method call receiver must be a classical type",
                    node.getReceiver().getPosition());
            return env.getErrorType();
        }

        // Look up method in receiver type
        MethodDeclaration method = lookupMethod(receiverType, node.getMethodName());
        if (method == null) {
            errors.report("Method not found: " + node.getMethodName(), node.getPosition());
            return env.getErrorType();
        }

        // Check argument types
        List<Parameter> params = method.getParameters();
        List<Expression> args = node.getArguments();

        if (params.size() != args.size()) {
            errors.report("Wrong number of arguments", node.getPosition());
            return env.getErrorType();
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
    public Type visitArrayAccess(ArrayAccess node) {
        Type arrayType = node.getArray().accept(this);
        Type indexType = node.getIndex().accept(this);

        if (!(arrayType instanceof ArrayType)) {
            errors.report("Array access requires array type", node.getArray().getPosition());
            return env.getErrorType();
        }

        if (!isIntegral(indexType)) {
            errors.report("Array index must be integral type", node.getIndex().getPosition());
            return env.getErrorType();
        }

        return ((ArrayType) arrayType).getElementType();
    }

    @Override
    public Type visitArrayInitializer(ArrayInitializer node) {
        return null;
    }

    @Override
    public Type visitAssignment(Assignment node) {
        Type targetType = node.getTarget().accept(this);
        Type valueType = node.getValue().accept(this);

        if (!isAssignable(targetType, valueType)) {
            errors.report("Incompatible types in assignment", node.getPosition());
            return env.getErrorType();
        }

        // Check compound assignments
        if (node.getOperator() != AssignmentOperator.ASSIGN) {
            switch (node.getOperator()) {
                case ADD_ASSIGN:
                case SUBTRACT_ASSIGN:
                case MULTIPLY_ASSIGN:
                case DIVIDE_ASSIGN:
                case MODULO_ASSIGN:
                    if (!isNumeric(targetType) || !isNumeric(valueType)) {
                        errors.report("Arithmetic compound assignment requires numeric types",
                                node.getPosition());
                    }
                    break;

                case AND_ASSIGN:
                case OR_ASSIGN:
                case XOR_ASSIGN:
                    if (!isIntegral(targetType) || !isIntegral(valueType)) {
                        errors.report("Bitwise compound assignment requires integral types",
                                node.getPosition());
                    }
                    break;
            }
        }

        return targetType;
    }

    // Quantum expressions

    @Override
    public Type visitQuantumType(QuantumType node) {
        // Perform quantum type validation
        switch (node.getKind()) {
            case QUREG:
                if (node.getSize() <= 0) {
                    errors.report("Quantum register size must be positive", node.getPosition());
                }
                break;
            case STATE:
                // State size validation will be done during initialization
                break;
            case QUBIT:
                // Single qubits don't need size validation
                break;
        }
        return node;
    }

    @Override
    public Type visitParameter(Parameter parameter) {
        return null;
    }

    @Override
    public Type visitQubitReference(QubitReference node) {
        Type type = env.lookup(node.getIdentifier());
        if (type == null) {
            errors.report("Undefined qubit: " + node.getIdentifier(), node.getPosition());
            return env.getErrorType();
        }
        if (!(type instanceof QuantumType) ||
                ((QuantumType) type).getKind() != QuantumTypeKind.QUBIT) {
            errors.report("Variable is not a qubit: " + node.getIdentifier(),
                    node.getPosition());
            return env.getErrorType();
        }
        return type;
    }

    @Override
    public Type visitTensorProduct(TensorProduct node) {
        for (QubitExpression factor : node.getFactors()) {
            Type factorType = factor.accept(this);
            if (!(factorType instanceof QuantumType)) {
                errors.report("Tensor product factor must be quantum type",
                        factor.getPosition());
            }
        }
        return env.getQuantumRegisterType(node.getFactors().size());
    }

    @Override
    public Type visitStateExpression(StateExpression node) {
        // Verify dimensions match number of qubits
        int expectedDimension = 1 << node.getNumQubits();
        if (node.getCoefficients().size() != expectedDimension) {
            errors.report("State vector size doesn't match number of qubits",
                    node.getPosition());
        }
        return env.getQuantumStateType(node.getNumQubits());
    }

    @Override
    public Type visitQuantumRegisterAccess(QuantumRegisterAccess node) {
        return null;
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
        return null;
    }

    @Override
    public Type visitQuantumCastExpression(QuantumCastExpression node) {
        return null;
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

    @Override
    public Type visitCleanBlock(CleanBlock node) {
        return null;
    }

    @Override
    public Type visitUncomputeBlock(UncomputeBlock node) {
        return null;
    }

    @Override
    public Type visitAllocationStatement(AllocationStatement node) {
        return null;
    }

    @Override
    public Type visitDeallocationStatement(DeallocationStatement node) {
        return null;
    }

    @Override
    public Type visitGarbageCollection(GarbageCollectionStatement node) {
        return null;
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

    // Quantum statements
    @Override
    public Type visitQuantumGateApplication(QuantumGateApplication node) {
        QuantumGate gate = node.getGate();
        List<QubitExpression> targets = node.getTargets();

        // Type check each target
        for (QubitExpression target : targets) {
            Type type = target.accept(this);
            if (!(type instanceof QuantumType) ||
                    ((QuantumType) type).getKind() != QuantumTypeKind.QUBIT) {
                errors.report("Gate target must be a qubit", target.getPosition());
            }
        }

        try {
            gate.validate(targets);
        } catch (IllegalArgumentException e) {
            errors.report(e.getMessage(), node.getPosition());
        }

        return env.getUnitType();
    }

    @Override
    public Type visitQuantumMeasurement(QuantumMeasurement node) {
        return null;
    }

    @Override
    public Type visitQuantumStatePreparation(QuantumStatePreparation node) {
        return null;
    }

    @Override
    public Type visitQuantumIfStatement(QuantumIfStatement node) {
        return null;
    }

    @Override
    public Type visitQuantumWhileStatement(QuantumWhileStatement node) {
        return null;
    }

    // Utility methods
    private boolean isNumeric(Type type) {
        return type instanceof ClassicalType &&
                ((ClassicalType) type).isNumeric();
    }

    private boolean isIntegral(Type type) {
        return type instanceof ClassicalType &&
                ((ClassicalType) type).isIntegral();
    }

    private boolean isBoolean(Type type) {
        return type instanceof ClassicalType &&
                ((ClassicalType) type).isBoolean();
    }

    private boolean isOrdered(Type type) {
        return type instanceof ClassicalType &&
                ((ClassicalType) type).isOrdered();
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
        return false;
    }

    private Type promoteNumeric(Type t1, Type t2) {
        if (!(t1 instanceof ClassicalType) || !(t2 instanceof ClassicalType)) {
            return env.getErrorType();
        }
        return ((ClassicalType) t1).promoteWith((ClassicalType) t2);
    }

    private MethodDeclaration lookupMethod(Type receiverType, String methodName) {
        if (!(receiverType instanceof ClassType classType)) {
            return null;
        }
        return classType.lookupMethod(methodName);
    }
}