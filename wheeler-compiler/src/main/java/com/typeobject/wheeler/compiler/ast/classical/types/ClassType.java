package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
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

public final class ClassType extends ClassicalType {
    private final Map<String, List<MethodDeclaration>> methods = new HashMap<>();
    private final ClassType supertype;
    private final List<ClassType> interfaces;
    private final Set<Modifier> modifiers;
    private final boolean isInterface;

    public ClassType(Position position, List<Annotation> annotations,
                     String name, List<Type> typeArguments,
                     ClassType supertype, List<ClassType> interfaces,
                     Set<Modifier> modifiers, boolean isInterface) {
        super(position, annotations, name, typeArguments, false);
        this.supertype = supertype;
        this.interfaces = interfaces != null ? new ArrayList<>(interfaces) : new ArrayList<>();
        this.modifiers = modifiers != null ? new HashSet<>(modifiers) : new HashSet<>();
        this.isInterface = isInterface;
    }

    private static ClassType findCommonSupertype(ClassType type1, ClassType type2) {
        Set<ClassType> type1Supertypes = getAllSupertypes(type1);
        Set<ClassType> type2Supertypes = getAllSupertypes(type2);
        type1Supertypes.retainAll(type2Supertypes);

        if (type1Supertypes.isEmpty()) {
            return null;
        }

        // Find most specific common supertype
        return type1Supertypes.stream()
                .reduce((t1, t2) -> t1.isSubtypeOf(t2) ? t1 : t2)
                .orElse(null);
    }

    private static Set<ClassType> getAllSupertypes(ClassType type) {
        Set<ClassType> supertypes = new HashSet<>();
        supertypes.add(type);

        if (type.supertype != null) {
            supertypes.addAll(getAllSupertypes(type.supertype));
        }

        for (ClassType iface : type.interfaces) {
            supertypes.addAll(getAllSupertypes(iface));
        }

        return supertypes;
    }

    public void addMethod(MethodDeclaration method) {
        methods.computeIfAbsent(method.getName(), k -> new ArrayList<>()).add(method);
    }

    public List<MethodDeclaration> getMethods(String name) {
        List<MethodDeclaration> result = methods.get(name);
        if (result != null) {
            return Collections.unmodifiableList(result);
        }

        // Check supertype methods
        if (supertype != null) {
            result = supertype.getMethods(name);
            if (!result.isEmpty()) {
                return result;
            }
        }

        // Check interface methods
        for (ClassType iface : interfaces) {
            result = iface.getMethods(name);
            if (!result.isEmpty()) {
                return result;
            }
        }

        return Collections.emptyList();
    }

    public List<MethodDeclaration> getMethods() {
        List<MethodDeclaration> allMethods = new ArrayList<>();
        methods.values().forEach(allMethods::addAll);

        // Add supertype methods
        if (supertype != null) {
            allMethods.addAll(supertype.getMethods());
        }

        // Add interface methods
        for (ClassType iface : interfaces) {
            allMethods.addAll(iface.getMethods());
        }

        return Collections.unmodifiableList(allMethods);
    }

    public MethodDeclaration lookupMethod(String name) {
        List<MethodDeclaration> methodList = getMethods(name);
        if (!methodList.isEmpty()) {
            return methodList.get(0);
        }
        return null;
    }

    public ClassType getSupertype() {
        return supertype;
    }

    public List<ClassType> getInterfaces() {
        return Collections.unmodifiableList(interfaces);
    }

    public Set<Modifier> getModifiers() {
        return Collections.unmodifiableSet(modifiers);
    }

    public boolean isInterface() {
        return isInterface;
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
        return interfaces.stream()
                .anyMatch(i -> i.getName().equals("Comparable"));
    }

    @Override
    public boolean isComparableTo(ClassicalType other) {
        if (equals(other)) {
            return true;
        }
        if (other instanceof ClassType) {
            return isSubtypeOf((ClassType) other) || ((ClassType) other).isSubtypeOf(this);
        }
        return false;
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        if (equals(source)) {
            return true;
        }
        if (source instanceof ClassType) {
            return ((ClassType) source).isSubtypeOf(this);
        }
        return false;
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        if (isAssignableFrom(other)) {
            return this;
        }
        if (other instanceof ClassType && other.isAssignableFrom(this)) {
            return other;
        }
        return findCommonSupertype(this, (ClassType) other);
    }

    private boolean isSubtypeOf(ClassType other) {
        if (this.equals(other)) {
            return true;
        }

        // Check supertype hierarchy
        if (supertype != null && supertype.isSubtypeOf(other)) {
            return true;
        }

        // Check interfaces
        for (ClassType iface : interfaces) {
            if (iface.isSubtypeOf(other)) {
                return true;
            }
        }

        return false;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitClassType(this);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ClassType classType)) return false;
        if (!super.equals(o)) return false;

        return isInterface == classType.isInterface &&
                Objects.equals(supertype, classType.supertype) &&
                interfaces.equals(classType.interfaces) &&
                modifiers.equals(classType.modifiers);
    }

    @Override
    public int hashCode() {
        return Objects.hash(super.hashCode(), supertype, interfaces, modifiers, isInterface);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        if (!modifiers.isEmpty()) {
            sb.append(modifiers).append(" ");
        }
        sb.append(isInterface ? "interface " : "class ").append(getName());

        List<Type> typeArgs = getTypeArguments();
        if (!typeArgs.isEmpty()) {
            sb.append('<');
            for (int i = 0; i < typeArgs.size(); i++) {
                if (i > 0) sb.append(", ");
                sb.append(typeArgs.get(i));
            }
            sb.append('>');
        }

        if (supertype != null) {
            sb.append(" extends ").append(supertype.getName());
        }

        if (!interfaces.isEmpty()) {
            sb.append(isInterface ? " extends " : " implements ");
            for (int i = 0; i < interfaces.size(); i++) {
                if (i > 0) sb.append(", ");
                sb.append(interfaces.get(i).getName());
            }
        }

        return sb.toString();
    }
}