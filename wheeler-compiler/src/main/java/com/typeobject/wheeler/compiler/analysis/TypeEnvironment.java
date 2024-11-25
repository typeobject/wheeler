package com.typeobject.wheeler.compiler.analysis;

import com.sun.jdi.ClassType;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.types.ArrayType;
import com.typeobject.wheeler.compiler.ast.classical.types.PrimitiveType;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumTypeKind;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class TypeEnvironment {
    private final TypeEnvironment parent;
    private final Map<String, Type> types;
    private final Map<String, Type> variables;
    private final Map<String, List<MethodSymbol>> methods;
    private final Type unitType;

    // Cached primitive and common types
    private final PrimitiveType booleanType;
    private final PrimitiveType byteType;
    private final PrimitiveType shortType;
    private final PrimitiveType intType;
    private final PrimitiveType longType;
    private final PrimitiveType floatType;
    private final PrimitiveType doubleType;
    private final PrimitiveType charType;
    private final PrimitiveType voidType;
    private final ClassType objectType;
    private final ClassType stringType;
    private final ClassType throwableType;
    private final ClassType errorType;
    private final QuantumType qubitType;
    private final QuantumType stateType;

    public TypeEnvironment(TypeEnvironment parent, Type unitType) {
        this.parent = parent;
        this.types = new HashMap<>();
        this.variables = new HashMap<>();
        this.methods = new HashMap<>();
        this.unitType = unitType;

        // Initialize primitive types
        this.booleanType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.BOOLEAN);
        this.byteType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.BYTE);
        this.shortType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.SHORT);
        this.intType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.INT);
        this.longType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.LONG);
        this.floatType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.FLOAT);
        this.doubleType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.DOUBLE);
        this.charType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.CHAR);
        this.voidType = new PrimitiveType(null, List.of(), PrimitiveType.Kind.VOID);

        // Initialize common reference types
        this.objectType = new ClassType(null, List.of(), "Object", List.of(), null, List.of());
        this.stringType = new ClassType(null, List.of(), "String", List.of(), objectType, List.of());
        this.throwableType = new ClassType(null, List.of(), "Throwable", List.of(), objectType, List.of());
        this.errorType = new ClassType(null, List.of(), "Error", List.of(), throwableType, List.of());

        // Initialize quantum types
        this.qubitType = new QuantumType(null, List.of(), QuantumTypeKind.QUBIT);
        this.stateType = new QuantumType(null, List.of(), QuantumTypeKind.STATE);

        // Register built-in types
        initializeBuiltinTypes();
    }

    private void initializeBuiltinTypes() {
        types.put("boolean", booleanType);
        types.put("byte", byteType);
        types.put("short", shortType);
        types.put("int", intType);
        types.put("long", longType);
        types.put("float", floatType);
        types.put("double", doubleType);
        types.put("char", charType);
        types.put("void", voidType);
        types.put("Object", objectType);
        types.put("String", stringType);
        types.put("Throwable", throwableType);
        types.put("qubit", qubitType);
        types.put("state", stateType);
    }

    // Type definition and lookup methods
    public void defineType(String name, Type type) {
        types.put(name, type);
    }

    public Type lookupType(String name) {
        Type type = types.get(name);
        if (type != null) return type;
        return parent != null ? parent.lookupType(name) : null;
    }

    // Variable definition and lookup methods
    public void defineVariable(String name, Type type) {
        variables.put(name, type);
    }

    public Type lookupVariable(String name) {
        Type type = variables.get(name);
        if (type != null) return type;
        return parent != null ? parent.lookupVariable(name) : null;
    }

    // Method definition and lookup methods
    public void defineMethod(String name, MethodSymbol method) {
        methods.computeIfAbsent(name, k -> new ArrayList<>()).add(method);
    }

    public List<MethodSymbol> lookupMethod(String name) {
        List<MethodSymbol> methodList = methods.get(name);
        if (methodList != null && !methodList.isEmpty()) return methodList;
        return parent != null ? parent.lookupMethod(name) : List.of();
    }

    // Common type getters
    public Type getUnitType() {
        return unitType;
    }

    public Type getBooleanType() {
        return booleanType;
    }

    public Type getByteType() {
        return byteType;
    }

    public Type getShortType() {
        return shortType;
    }

    public Type getIntType() {
        return intType;
    }

    public Type getLongType() {
        return longType;
    }

    public Type getFloatType() {
        return floatType;
    }

    public Type getDoubleType() {
        return doubleType;
    }

    public Type getCharType() {
        return charType;
    }

    public Type getVoidType() {
        return voidType;
    }

    public Type getObjectType() {
        return objectType;
    }

    public Type getStringType() {
        return stringType;
    }

    public Type getThrowableType() {
        return throwableType;
    }

    public Type getErrorType() {
        return errorType;
    }

    public Type getQubitType() {
        return qubitType;
    }

    public Type getStateType() {
        return stateType;
    }

    // Array type creation
    public Type getArrayType(Type elementType, int dimensions) {
        return new ArrayType(null, List.of(), elementType, dimensions);
    }

    // Quantum register type creation
    public Type getQuantumRegisterType(int size) {
        return new QuantumType(null, List.of(), QuantumTypeKind.QUREG, size);
    }

    // Functional interface type creation
    public Type getFunctionalInterfaceType(List<Parameter> parameters, Type returnType) {
        String name = "Function" + parameters.size();
        List<Type> typeArgs = new ArrayList<>();
        for (Parameter param : parameters) {
            typeArgs.add(param.getType());
        }
        typeArgs.add(returnType);
        return new ClassType(null, List.of(), name, typeArgs, objectType, List.of());
    }

    // Method symbol for overload resolution
    public static class MethodSymbol {
        private final String name;
        private final List<Parameter> parameters;
        private final Type returnType;
        private final Set<Modifier> modifiers;

        public MethodSymbol(String name, List<Parameter> parameters, Type returnType, Set<Modifier> modifiers) {
            this.name = name;
            this.parameters = parameters;
            this.returnType = returnType;
            this.modifiers = modifiers;
        }

        public String getName() {
            return name;
        }

        public List<Parameter> getParameters() {
            return parameters;
        }

        public Type getReturnType() {
            return returnType;
        }

        public Set<Modifier> getModifiers() {
            return modifiers;
        }

        public boolean isStatic() {
            return modifiers.contains(Modifier.STATIC);
        }

        public boolean isPublic() {
            return modifiers.contains(Modifier.PUBLIC);
        }

        public boolean isPrivate() {
            return modifiers.contains(Modifier.PRIVATE);
        }

        public boolean isProtected() {
            return modifiers.contains(Modifier.PROTECTED);
        }

        // Method signature matching
        public boolean matches(List<Type> argumentTypes) {
            if (parameters.size() != argumentTypes.size()) return false;
            for (int i = 0; i < parameters.size(); i++) {
                Type paramType = parameters.get(i).getType();
                Type argType = argumentTypes.get(i);
                if (!isAssignable(paramType, argType)) return false;
            }
            return true;
        }
    }

    // Type compatibility checking methods
    public static boolean isAssignable(Type target, Type source) {
        if (target.equals(source)) return true;
        if (target instanceof ClassType && source instanceof ClassType) {
            return isClassAssignable((ClassType) target, (ClassType) source);
        }
        if (target instanceof ArrayType && source instanceof ArrayType) {
            return isArrayAssignable((ArrayType) target, (ArrayType) source);
        }
        if (target instanceof QuantumType && source instanceof QuantumType) {
            return isQuantumAssignable((QuantumType) target, (QuantumType) source);
        }
        return false;
    }

    private static boolean isClassAssignable(ClassType target, ClassType source) {
        if (target == source) return true;
        if (source.getSupertype() != null && isClassAssignable(target, source.getSupertype())) {
            return true;
        }
        for (ClassType iface : source.getInterfaces()) {
            if (isClassAssignable(target, iface)) return true;
        }
        return false;
    }

    private static boolean isArrayAssignable(ArrayType target, ArrayType source) {
        if (target.getDimensions() != source.getDimensions()) return false;
        return isAssignable(target.getElementType(), source.getElementType());
    }

    private static boolean isQuantumAssignable(QuantumType target, QuantumType source) {
        if (target.getKind() != source.getKind()) return false;
        if (target.getKind() == QuantumTypeKind.QUREG) {
            return target.getSize() == source.getSize();
        }
        return true;
    }

    // Method overload resolution
    public MethodSymbol resolveMethod(String name, List<Type> argumentTypes) {
        List<MethodSymbol> candidates = lookupMethod(name);
        List<MethodSymbol> matches = new ArrayList<>();

        // Find all matching methods
        for (MethodSymbol method : candidates) {
            if (method.matches(argumentTypes)) {
                matches.add(method);
            }
        }

        if (matches.isEmpty()) return null;
        if (matches.size() == 1) return matches.get(0);

        // Find most specific method
        MethodSymbol best = matches.get(0);
        for (int i = 1; i < matches.size(); i++) {
            MethodSymbol current = matches.get(i);
            if (isMoreSpecific(current, best)) {
                best = current;
            }
        }

        return best;
    }

    private boolean isMoreSpecific(MethodSymbol m1, MethodSymbol m2) {
        List<Parameter> params1 = m1.getParameters();
        List<Parameter> params2 = m2.getParameters();

        boolean m1MoreSpecific = true;
        boolean m2MoreSpecific = true;

        for (int i = 0; i < params1.size(); i++) {
            Type type1 = params1.get(i).getType();
            Type type2 = params2.get(i).getType();

            if (!isAssignable(type2, type1)) m1MoreSpecific = false;
            if (!isAssignable(type1, type2)) m2MoreSpecific = false;
        }

        return m1MoreSpecific && !m2MoreSpecific;
    }

    // Scope management
    public TypeEnvironment createChildScope() {
        return new TypeEnvironment(this, this.unitType);
    }

    public TypeEnvironment getParent() {
        return parent;
    }

    // Type checking utilities
    public boolean isSubtype(Type type1, Type type2) {
        return isAssignable(type2, type1);
    }

    public Type getLeastUpperBound(Type type1, Type type2) {
        if (isAssignable(type1, type2)) return type1;
        if (isAssignable(type2, type1)) return type2;

        if (type1 instanceof ClassType && type2 instanceof ClassType) {
            return findCommonSupertype((ClassType) type1, (ClassType) type2);
        }

        return objectType;
    }

    private Type findCommonSupertype(ClassType type1, ClassType type2) {
        Set<ClassType> type1Supertypes = getAllSupertypes(type1);
        Set<ClassType> type2Supertypes = getAllSupertypes(type2);

        type1Supertypes.retainAll(type2Supertypes);

        if (type1Supertypes.isEmpty()) return objectType;

        // Find most specific common supertype
        ClassType result = null;
        for (ClassType type : type1Supertypes) {
            if (result == null || isAssignable(result, type)) {
                result = type;
            }
        }

        return result != null ? result : objectType;
    }

    private Set<ClassType> getAllSupertypes(ClassType type) {
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