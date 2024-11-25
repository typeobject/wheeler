package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/**
 * Base class for all classical (non-quantum) types in the Wheeler language.
 */
public abstract class ClassicalType extends Type {
    private final String name;
    private final List<Type> typeArguments;
    private final boolean isPrimitive;

    protected ClassicalType(Position position, List<Annotation> annotations,
                            String name, List<Type> typeArguments,
                            boolean isPrimitive) {
        super(position, annotations);
        this.name = name;
        this.typeArguments = new ArrayList<>(typeArguments != null ? typeArguments : Collections.emptyList());
        this.isPrimitive = isPrimitive;
    }

    /**
     * Factory method for creating primitive types.
     */
    public static ClassicalType createPrimitive(Position position,
                                                List<Annotation> annotations,
                                                PrimitiveType.Kind kind) {
        return new PrimitiveType(position, annotations, kind);
    }

    /**
     * Factory method for creating class types.
     */
    public static ClassicalType createClass(Position position,
                                            List<Annotation> annotations,
                                            String name,
                                            List<Type> typeArguments,
                                            ClassType supertype,
                                            List<ClassType> interfaces) {
        Set<Modifier> modifiers = new HashSet<>();
        return new ClassType(position, annotations, name, typeArguments,
                supertype, interfaces, modifiers, false);
    }

    /**
     * Factory method for creating array types.
     */
    public static ClassicalType createArray(Position position,
                                            List<Annotation> annotations,
                                            Type elementType,
                                            int dimensions) {
        return new ArrayType(position, annotations, elementType, dimensions);
    }

    /**
     * Factory method for creating type parameters.
     */
    public static ClassicalType createTypeParameter(Position position,
                                                    List<Annotation> annotations,
                                                    String name,
                                                    List<Type> bounds) {
        return new TypeParameter(position, annotations, name, bounds);
    }

    /**
     * Factory method for creating wildcard types.
     */
    public static ClassicalType createWildcard(Position position,
                                               List<Annotation> annotations,
                                               WildcardType.BoundKind boundKind,
                                               Type bound) {
        return new WildcardType(position, annotations, boundKind, bound);
    }

    /**
     * Helper method to determine if a type is a subtype of another.
     */
    public static boolean isSubtype(ClassicalType sub, ClassicalType sup) {
        return sup.isAssignableFrom(sub);
    }

    /**
     * Helper method to find the least upper bound of two types.
     */
    public static ClassicalType leastUpperBound(ClassicalType t1, ClassicalType t2) {
        if (t1.isAssignableFrom(t2)) return t1;
        if (t2.isAssignableFrom(t1)) return t2;

        // For class types, find the most specific common supertype
        if (t1 instanceof ClassType && t2 instanceof ClassType) {
            Set<ClassType> t1Supertypes = getAllSupertypes((ClassType) t1);
            Set<ClassType> t2Supertypes = getAllSupertypes((ClassType) t2);
            t1Supertypes.retainAll(t2Supertypes);

            return t1Supertypes.stream()
                    .filter(t -> t instanceof ClassicalType)
                    .map(t -> (ClassicalType) t)
                    .reduce((c1, c2) -> c1.isAssignableFrom(c2) ? c2 : c1)
                    .orElse(null);
        }

        return null;
    }

    private static Set<ClassType> getAllSupertypes(ClassType type) {
        Set<ClassType> supertypes = new HashSet<>();
        supertypes.add(type);

        if (type.getSupertype() != null) {
            supertypes.addAll(getAllSupertypes(type.getSupertype()));
        }

        for (ClassType iface : type.getInterfaces()) {
            supertypes.addAll(getAllSupertypes(iface));
        }

        return supertypes;
    }

    /**
     * Gets the name of this type.
     */
    public String getName() {
        return name;
    }

    /**
     * Gets the type arguments if this is a generic type.
     */
    public List<Type> getTypeArguments() {
        return Collections.unmodifiableList(typeArguments);
    }

    /**
     * Returns true if this is a primitive type.
     */
    public boolean isPrimitive() {
        return isPrimitive;
    }

    /**
     * Returns true if this type represents a classical (non-quantum) type.
     */
    @Override
    public boolean isClassical() {
        return true;
    }

    /**
     * Returns true if this type represents a numeric type.
     */
    public abstract boolean isNumeric();

    /**
     * Returns true if this type represents an integral type.
     */
    public abstract boolean isIntegral();

    /**
     * Returns true if this type represents the boolean type.
     */
    public abstract boolean isBoolean();

    /**
     * Returns true if values of this type can be ordered.
     */
    public abstract boolean isOrdered();

    /**
     * Returns true if values of this type can be compared for equality with values of the given type.
     */
    public abstract boolean isComparableTo(ClassicalType other);

    /**
     * Returns true if values of the given type can be assigned to variables of this type.
     */
    public abstract boolean isAssignableFrom(ClassicalType source);

    /**
     * Returns the result type when this type is used in an arithmetic operation with the other type,
     * or null if the types cannot be combined arithmetically.
     */
    public abstract Type promoteWith(ClassicalType other);

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ClassicalType that)) return false;

        return isPrimitive == that.isPrimitive &&
                Objects.equals(name, that.name) &&
                Objects.equals(typeArguments, that.typeArguments);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, typeArguments, isPrimitive);
    }

    /**
     * Returns the fully qualified name of this type, including type arguments.
     */
    protected String getQualifiedName() {
        if (typeArguments.isEmpty()) {
            return name;
        }

        StringBuilder sb = new StringBuilder(name);
        sb.append('<');
        for (int i = 0; i < typeArguments.size(); i++) {
            if (i > 0) {
                sb.append(", ");
            }
            sb.append(typeArguments.get(i));
        }
        sb.append('>');
        return sb.toString();
    }

    @Override
    public String toString() {
        return getQualifiedName();
    }
}