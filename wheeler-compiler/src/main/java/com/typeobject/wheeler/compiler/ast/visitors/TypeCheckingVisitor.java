package com.typeobject.wheeler.compiler.ast.visitors;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.*;
import com.typeobject.wheeler.compiler.ast.base.*;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.classical.declarations.*;
import com.typeobject.wheeler.compiler.ast.classical.expressions.*;
import com.typeobject.wheeler.compiler.ast.classical.statements.*;
import com.typeobject.wheeler.compiler.ast.classical.types.*;
import com.typeobject.wheeler.compiler.ast.memory.*;
import com.typeobject.wheeler.compiler.ast.quantum.expressions.*;
import com.typeobject.wheeler.compiler.ast.quantum.gates.*;
import com.typeobject.wheeler.compiler.ast.quantum.statements.*;
import com.typeobject.wheeler.compiler.ast.quantum.types.*;
import com.typeobject.wheeler.compiler.analysis.TypeEnvironment;
import com.typeobject.wheeler.compiler.ErrorReporter;

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
  public Type visitQuantumArrayAccess(QuantumArrayAccess node) {
    return null;
  }

  @Override
  public Type visitQuantumCastExpression(QuantumCastExpression node) {
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
    if (!(receiverType instanceof ClassicalType)) {
      return null;
    }
    ClassicalType classType = (ClassicalType) receiverType;
    return classType.lookupMethod(methodName);
  }
}