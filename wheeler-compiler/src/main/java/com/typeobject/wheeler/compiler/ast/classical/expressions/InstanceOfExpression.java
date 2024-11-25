package com.typeobject.wheeler.compiler.ast.classical.expressions;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.types.ClassType;
import com.typeobject.wheeler.compiler.ast.classical.types.ClassicalType;
import java.util.List;
import java.util.Objects;

/**
 * Represents an instanceof expression in the Wheeler language.
 * For example: "obj instanceof String"
 */
public final class InstanceOfExpression extends Expression {
    private final Expression expression;
    private final Type type;
    private final String identifier; // For pattern matching, can be null

    /**
     * Creates an instanceof expression without pattern matching.
     */
    public InstanceOfExpression(Position position, List<Annotation> annotations,
                                Expression expression, Type type) {
        this(position, annotations, expression, type, null);
    }

    /**
     * Creates an instanceof expression with optional pattern matching.
     */
    public InstanceOfExpression(Position position, List<Annotation> annotations,
                                Expression expression, Type type, String identifier) {
        super(position, annotations);
        this.expression = expression;
        this.type = type;
        this.identifier = identifier;
    }

    /**
     * Gets the expression being tested.
     */
    public Expression getExpression() {
        return expression;
    }

    /**
     * Gets the type being tested against.
     */
    public Type getType() {
        return type;
    }

    /**
     * Gets the pattern variable identifier, if this is a pattern matching instanceof.
     */
    public String getPatternIdentifier() {
        return identifier;
    }

    /**
     * Returns true if this is a pattern matching instanceof expression.
     */
    public boolean hasPattern() {
        return identifier != null;
    }

    /**
     * Creates a new InstanceOfExpression with a pattern variable.
     */
    public InstanceOfExpression withPattern(String patternIdentifier) {
        return new InstanceOfExpression(getPosition(), getAnnotations(),
                expression, type, patternIdentifier);
    }

    /**
     * Creates a new InstanceOfExpression with an updated expression.
     */
    public InstanceOfExpression withExpression(Expression newExpression) {
        return new InstanceOfExpression(getPosition(), getAnnotations(),
                newExpression, type, identifier);
    }

    /**
     * Creates a new InstanceOfExpression with an updated type.
     */
    public InstanceOfExpression withType(Type newType) {
        return new InstanceOfExpression(getPosition(), getAnnotations(),
                expression, newType, identifier);
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitInstanceOf(this);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof InstanceOfExpression that)) return false;
        if (!super.equals(o)) return false;

        return expression.equals(that.expression) &&
                type.equals(that.type) &&
                Objects.equals(identifier, that.identifier);
    }

    @Override
    public int hashCode() {
        return Objects.hash(super.hashCode(), expression, type, identifier);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(expression);
        sb.append(" instanceof ");
        sb.append(type);
        if (identifier != null) {
            sb.append(' ').append(identifier);
        }
        return sb.toString();
    }

    /**
     * Helper method to check if the instanceof could ever evaluate to true.
     */
    public boolean isPossible() {
        if (!(expression.getType() instanceof ClassicalType exprType) ||
                !(type instanceof ClassicalType testType)) {
            return false;
        }

        // Same type always possible
        if (exprType.equals(testType)) {
            return true;
        }

        // Check assignability
        if (testType.isAssignableFrom(exprType) ||
                exprType.isAssignableFrom(testType)) {
            return true;
        }

        // If either type is an interface, it's possible
        return testType instanceof ClassType &&
                ((ClassType) testType).isInterface();
    }

    /**
     * Helper method to check if the instanceof will always evaluate to true.
     */
    public boolean isAlwaysTrue() {
        if (!(expression.getType() instanceof ClassicalType exprType) ||
                !(type instanceof ClassicalType testType)) {
            return false;
        }

        return exprType.equals(testType) || testType.isAssignableFrom(exprType);
    }

    /**
     * Helper method to check if the instanceof will always evaluate to false.
     */
    public boolean isAlwaysFalse() {
        return !isPossible();
    }
}