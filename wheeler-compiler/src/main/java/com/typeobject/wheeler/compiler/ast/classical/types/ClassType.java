package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.declarations.ConstructorDeclaration;
import com.typeobject.wheeler.compiler.ast.classical.declarations.FieldDeclaration;
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
    private final String name;
    private final List<Type> typeArguments;
    private final ClassType supertype;
    private final List<ClassType> interfaces;
    private final Set<Modifier> modifiers;
    private final Map<String, FieldDeclaration> fields;
    private final Map<String, List<MethodDeclaration>> methods;
    private final List<ConstructorDeclaration> constructors;
    private final boolean isInterface;

    public ClassType(Position position,
                     List<Annotation> annotations,
                     String name,
                     List<Type> typeArguments,
                     ClassType supertype,
                     List<ClassType> interfaces,
                     Set<Modifier> modifiers,
                     boolean isInterface) {
        super(position, annotations, name, typeArguments, false);
        this.name = name;
        this.typeArguments = new ArrayList<>(typeArguments);
        this.supertype = supertype;
        this.interfaces = new ArrayList<>(interfaces);
        this.modifiers = new HashSet<>(modifiers);
        this.fields = new HashMap<>();
        this.methods = new HashMap<>();
        this.constructors = new ArrayList<>();
        this.isInterface = isInterface;
    }

    // Basic getters
    public String getName() {
        return name;
    }

    public List<Type> getTypeArguments() {
        return Collections.unmodifiableList(typeArguments);
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

    // Member management
    public void addField(FieldDeclaration field) {
        fields.put(field.getName(), field);
    }

    public void addMethod(MethodDeclaration method) {
        methods.computeIfAbsent(method.getName(), k -> new ArrayList<>()).add(method);
    }

    public void addConstructor(ConstructorDeclaration constructor) {
        constructors.add(constructor);
    }

    public FieldDeclaration getField(String name) {
        FieldDeclaration field = fields.get(name);
        if (field != null) return field;
        if (supertype != null) return supertype.getField(name);
        return null;
    }

    public List<MethodDeclaration> getMethods(String name) {
        List<MethodDeclaration> result = new ArrayList<>();

        // Add methods from this class
        List<MethodDeclaration> localMethods = methods.get(name);
        if (localMethods != null) {
            result.addAll(localMethods);
        }

        // Add methods from superclass
        if (supertype != null) {
            List<MethodDeclaration> superMethods = supertype.getMethods(name);
            for (MethodDeclaration superMethod : superMethods) {
                if (!isOverridden(superMethod, result)) {
                    result.add(superMethod);
                }
            }
        }

        // Add methods from interfaces
        for (ClassType iface : interfaces) {
            List<MethodDeclaration> ifaceMethods = iface.getMethods(name);
            for (MethodDeclaration ifaceMethod : ifaceMethods) {
                if (!isOverridden(ifaceMethod, result)) {
                    result.add(ifaceMethod);
                }
            }
        }

        return result;
    }

    public List<ConstructorDeclaration> getConstructors() {
        return Collections.unmodifiableList(constructors);
    }

    // Method lookup and override checking
    private boolean isOverridden(MethodDeclaration method, List<MethodDeclaration> methods) {
        for (MethodDeclaration existing : methods) {
            if (overrides(existing, method)) {
                return true;
            }
        }
        return false;
    }

    private boolean overrides(MethodDeclaration method1, MethodDeclaration method2) {
        if (!method1.getName().equals(method2.getName())) return false;

        List<Type> params1 = getParameterTypes(method1);
        List<Type> params2 = getParameterTypes(method2);

        if (params1.size() != params2.size()) return false;

        for (int i = 0; i < params1.size(); i++) {
            if (!params1.get(i).equals(params2.get(i))) return false;
        }

        return true;
    }

    private List<Type> getParameterTypes(MethodDeclaration method) {
        return method.getParameters().stream()
                .map(p -> p.getType())
                .toList();
    }

    // Type system implementation
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
        // Check if this type implements Comparable
        return interfaces.stream().anyMatch(i -> i.getName().equals("Comparable"));
    }

    @Override
    public boolean isComparableTo(ClassicalType other) {
        if (equals(other)) return true;
        if (other instanceof ClassType) {
            ClassType otherClass = (ClassType) other;
            // Check if this type is assignable to the other type or vice versa
            return isAssignableFrom(otherClass) || otherClass.isAssignableFrom(this);
        }
        return false;
    }

    @Override
    public boolean isAssignableFrom(ClassicalType source) {
        if (!(source instanceof ClassType)) return false;
        ClassType sourceClass = (ClassType) source;

        // Same type
        if (this.equals(sourceClass)) return true;

        // Check superclass hierarchy
        if (sourceClass.supertype != null && isAssignableFrom(sourceClass.supertype)) {
            return true;
        }

        // Check interfaces
        for (ClassType iface : sourceClass.interfaces) {
            if (isAssignableFrom(iface)) return true;
        }

        return false;
    }

    @Override
    public Type promoteWith(ClassicalType other) {
        if (isAssignableFrom(other)) return this;
        if (other instanceof ClassType && ((ClassType) other).isAssignableFrom(this)) {
            return other;
        }
        // Find least common supertype
        if (other instanceof ClassType) {
            return findCommonSupertype(this, (ClassType) other);
        }
        return null;
    }

    private ClassType findCommonSupertype(ClassType type1, ClassType type2) {
        Set<ClassType> type1Supertypes = getAllSupertypes(type1);
        Set<ClassType> type2Supertypes = getAllSupertypes(type2);

        type1Supertypes.retainAll(type2Supertypes);

        if (type1Supertypes.isEmpty()) return null;

        // Find most specific common supertype
        return type1Supertypes.stream()
                .reduce((t1, t2) -> t1.isAssignableFrom(t2) ? t2 : t1)
                .orElse(null);
    }

    private Set<ClassType> getAllSupertypes(ClassType type) {
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

    // Type substitution for generics
    public ClassType substitute(Map<TypeParameter, Type> substitutions) {
        List<Type> newTypeArgs = new ArrayList<>();
        for (Type arg : typeArguments) {
            if (arg instanceof TypeParameter) {
                Type substitution = substitutions.get(arg);
                newTypeArgs.add(substitution != null ? substitution : arg);
            } else {
                newTypeArgs.add(arg);
            }
        }

        return new ClassType(
                getPosition(),
                getAnnotations(),
                name,
                newTypeArgs,
                supertype != null ? supertype.substitute(substitutions) : null,
                interfaces.stream()
                        .map(i -> i.substitute(substitutions))
                        .toList(),
                modifiers,
                isInterface
        );
    }

    // Equality and hashing
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ClassType)) return false;

        ClassType that = (ClassType) o;
        return name.equals(that.name) &&
                typeArguments.equals(that.typeArguments) &&
                Objects.equals(supertype, that.supertype) &&
                interfaces.equals(that.interfaces);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, typeArguments, supertype, interfaces);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder(name);
        if (!typeArguments.isEmpty()) {
            sb.append('<');
            for (int i = 0; i < typeArguments.size(); i++) {
                if (i > 0) sb.append(", ");
                sb.append(typeArguments.get(i));
            }
            sb.append('>');
        }
        return sb.toString();
    }

    // Visitor pattern implementation
    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitClassType(this);
    }

    // Builder pattern for convenient instantiation
    public static class Builder {
        private Position position;
        private List<Annotation> annotations = new ArrayList<>();
        private String name;
        private List<Type> typeArguments = new ArrayList<>();
        private ClassType supertype;
        private List<ClassType> interfaces = new ArrayList<>();
        private Set<Modifier> modifiers = new HashSet<>();
        private boolean isInterface;

        public Builder(String name) {
            this.name = name;
        }

        public Builder position(Position position) {
            this.position = position;
            return this;
        }

        public Builder addAnnotation(Annotation annotation) {
            this.annotations.add(annotation);
            return this;
        }

        public Builder addTypeArgument(Type typeArg) {
            this.typeArguments.add(typeArg);
            return this;
        }

        public Builder supertype(ClassType supertype) {
            this.supertype = supertype;
            return this;
        }

        public Builder addInterface(ClassType iface) {
            this.interfaces.add(iface);
            return this;
        }

        public Builder addModifier(Modifier modifier) {
            this.modifiers.add(modifier);
            return this;
        }

        public Builder setInterface(boolean isInterface) {
            this.isInterface = isInterface;
            return this;
        }

        public ClassType build() {
            return new ClassType(
                    position,
                    annotations,
                    name,
                    typeArguments,
                    supertype,
                    interfaces,
                    modifiers,
                    isInterface
            );
        }
    }
}