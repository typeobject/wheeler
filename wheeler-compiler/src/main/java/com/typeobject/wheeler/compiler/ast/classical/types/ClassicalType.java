package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.declarations.MethodDeclaration;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Base class for all classical (non-quantum) types in the Wheeler language.
 * This includes primitive types, class types, array types, and type parameters.
 */
public abstract class ClassicalType extends Type {
    private final String name;
    private final List<Type> typeArguments;
    private final boolean isPrimitive;
    private final Map<String, List<MethodDeclaration>> methods;

    protected ClassicalType(Position position,
                            List<Annotation> annotations,
                            String name,
                            List<Type> typeArguments,
                            boolean isPrimitive) {
        super(position, annotations);
        this.name = name;
        this.typeArguments = new ArrayList<>(typeArguments);
        this.isPrimitive = isPrimitive;
        this.methods = new HashMap<>();
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
     * Returns true if this type represents a numeric type (int, long, float, etc).
     */
    public abstract boolean isNumeric();

    /**
     * Returns true if this type represents an integral type (byte, short, int, long).
     */
    public abstract boolean isIntegral();

    /**
     * Returns true if this type represents the boolean type.
     */
    public abstract boolean isBoolean();

    /**
     * Returns true if values of this type can be ordered (compared with <, >, etc).
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

    /**
     * Add a method to this type's method table.
     */
    public void addMethod(MethodDeclaration method) {
        methods.computeIfAbsent(method.getName(), k -> new ArrayList<>())
                .add(method);
    }

    /**
     * Look up methods by name.
     */
    public List<MethodDeclaration> getMethods(String name) {
        List<MethodDeclaration> result = methods.get(name);
        return result != null ? Collections.unmodifiableList(result) : Collections.emptyList();
    }

    /**
     * Find a method that matches the given argument types.
     */
    public MethodDeclaration findMethod(String name, List<Type> argumentTypes) {
        List<MethodDeclaration> candidates = getMethods(name);
        List<MethodDeclaration> matches = new ArrayList<>();

        // Find methods with matching parameter counts
        for (MethodDeclaration method : candidates) {
            if (method.getParameters().size() == argumentTypes.size()) {
                matches.add(method);
            }
        }

        // Find methods with compatible parameter types
        List<MethodDeclaration> compatibleMethods = new ArrayList<>();
        for (MethodDeclaration method : matches) {
            boolean isCompatible = true;
            for (int i = 0; i < argumentTypes.size(); i++) {
                Type paramType = method.getParameters().get(i).getType();
                Type argType = argumentTypes.get(i);
                if (!(paramType instanceof ClassicalType &&
                        argType instanceof ClassicalType &&
                        ((ClassicalType) paramType).isAssignableFrom((ClassicalType) argType))) {
                    isCompatible = false;
                    break;
                }
            }
            if (isCompatible) {
                compatibleMethods.add(method);
            }
        }

        if (compatibleMethods.isEmpty()) {
            return null;
        }

        // Find most specific method
        MethodDeclaration mostSpecific = compatibleMethods.get(0);
        for (int i = 1; i < compatibleMethods.size(); i++) {
            MethodDeclaration current = compatibleMethods.get(i);
            if (isMoreSpecific(current, mostSpecific)) {
                mostSpecific = current;
            }
        }

        return mostSpecific;
    }

    /**
     * Determines if one method is more specific than another.
     */
    private boolean isMoreSpecific(MethodDeclaration m1, MethodDeclaration m2) {
        boolean m1MoreSpecific = true;
        boolean m2MoreSpecific = true;

        for (int i = 0; i < m1.getParameters().size(); i++) {
            Type t1 = m1.getParameters().get(i).getType();
            Type t2 = m2.getParameters().get(i).getType();

            if (t1 instanceof ClassicalType && t2 instanceof ClassicalType) {
                ClassicalType ct1 = (ClassicalType) t1;
                ClassicalType ct2 = (ClassicalType) t2;

                if (!ct2.isAssignableFrom(ct1)) {
                    m1MoreSpecific = false;
                }
                if (!ct1.isAssignableFrom(ct2)) {
                    m2MoreSpecific = false;
                }
            }
        }

        return m1MoreSpecific && !m2MoreSpecific;
    }

    /**
     * Substitutes type parameters with actual types based on the given substitution map.
     */
    public ClassicalType substitute(Map<TypeParameter, Type> substitutions) {
        // Default implementation returns this type unchanged
        return this;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ClassicalType)) return false;

        ClassicalType that = (ClassicalType) o;
        return name.equals(that.name) &&
                typeArguments.equals(that.typeArguments) &&
                isPrimitive == that.isPrimitive;
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
        return new ClassType(position, annotations, name, typeArguments,
                supertype, interfaces);
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
}