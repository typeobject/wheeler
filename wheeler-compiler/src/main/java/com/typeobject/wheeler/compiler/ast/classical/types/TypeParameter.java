package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * Represents a type parameter in a generic type or method declaration.
 * For example, in List<T>, T is a type parameter.
 */
public final class TypeParameter extends ClassicalType {
    private final String name;
    private final List<Type> bounds;
    private final boolean isVariance; // true if this is a variant type parameter (? extends, ? super)

    public TypeParameter(Position position, List<Annotation> annotations,
                         String name, List<Type> bounds) {
        this(position, annotations, name, bounds, false);
    }

    public TypeParameter(Position position, List<Annotation> annotations,
                         String name, List<Type> bounds, boolean isVariance) {
        super(position, annotations, name, List.of(), false);
        this.name = name;
        this.bounds = bounds != null ? new ArrayList<>(bounds) : new ArrayList<>();
        this.isVariance = isVariance;
    }

    /**
     * Gets the name of this type parameter.
     */
    @Override
    public String getName() {
        return name;
    }

    /**
     * Gets the bounds of this type parameter.
     * For example, in T extends Number & Comparable<T>,
     * the bounds are [Number, Comparable<T>].
     */
    public List<Type> getBounds() {
        return Collections.unmodifiableList(bounds);
    }

    /**
     * Returns true if this is a variance type parameter (? extends, ? super).
     */
    public boolean isVariance() {
        return isVariance;
    }

    @Override
    public boolean isNumeric() {
        return false;
    }

    @Override
    public boolean isIntegral() {
        return false;
    }

    @Override
    public boolean isBoolean() {
        return false;
    }

    @Override
    public boolean isOrdered() {
        return bounds.stream()
                .anyMatch(bound -> bound instanceof ClassicalType && ((ClassicalType) bound).isOrdered());
    }

    @Override
    public boolean isComparableTo(ClassicalType other) {
        // A type parameter is comparable if any of its bounds is comparable
        for (Type bound : bounds) {
            if (bound instanceof ClassicalType && ((ClassicalType) bound).isComparableTo(other)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        // Nothing can be assigned to a variance type parameter
        if (isVariance) {
            return false;
        }

        // Check if source type satisfies all bounds
        for (Type bound : bounds) {
            if (bound instanceof ClassicalType) {
                if (!((ClassicalType) bound).isAssignableFrom(source)) {
                    return false;
                }
            }
        }
        return true;
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        // Type parameters can't be promoted with other types
        return null;
    }

    /**
     * Creates a copy of this type parameter with new bounds.
     */
    public TypeParameter withBounds(List<Type> newBounds) {
        return new TypeParameter(getPosition(), getAnnotations(), name, newBounds, isVariance);
    }

    /**
     * Creates a variance (wildcard) version of this type parameter.
     */
    public TypeParameter asVariance() {
        return new TypeParameter(getPosition(), getAnnotations(), name, bounds, true);
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitTypeParameter(this);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TypeParameter that)) return false;
        if (!super.equals(o)) return false;

        return isVariance == that.isVariance &&
                name.equals(that.name) &&
                bounds.equals(that.bounds);
    }

    @Override
    public int hashCode() {
        return Objects.hash(super.hashCode(), name, bounds, isVariance);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        if (isVariance) {
            sb.append('?');
            if (!bounds.isEmpty()) {
                sb.append(" extends ");
            }
        } else {
            sb.append(name);
        }

        if (!bounds.isEmpty()) {
            if (!isVariance) {
                sb.append(" extends ");
            }
            for (int i = 0; i < bounds.size(); i++) {
                if (i > 0) {
                    sb.append(" & ");
                }
                sb.append(bounds.get(i));
            }
        }
        return sb.toString();
    }
}