package com.typeobject.wheeler.compiler.analysis;

import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.types.ClassType;
import com.typeobject.wheeler.compiler.ast.classical.types.PrimitiveType;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumType;
import com.typeobject.wheeler.compiler.ast.quantum.types.QuantumTypeKind;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Maintains type information and provides type lookup functionality.
 */
public class TypeEnvironment {
    private final TypeEnvironment parent;
    private final Map<String, Type> types;
    private final Map<String, Type> variables;
    private final Type unitType;

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
    private final Type nullType;

    public TypeEnvironment(TypeEnvironment parent, Type unitType) {
        this.parent = parent;
        this.types = new HashMap<>();
        this.variables = new HashMap<>();
        this.unitType = unitType;

        // Initialize primitive types
        Set<Modifier> noModifiers = new HashSet<>();
        List<Type> noTypeParams = new ArrayList<>();
        List<ClassType> noInterfaces = new ArrayList<>();

        // Initialize object type first since others depend on it
        this.objectType = new ClassType(null, List.of(), "Object", noTypeParams, null, noInterfaces, noModifiers, false);
        this.stringType = new ClassType(null, List.of(), "String", noTypeParams, objectType, noInterfaces, noModifiers, false);
        this.throwableType = new ClassType(null, List.of(), "Throwable", noTypeParams, objectType, noInterfaces, noModifiers, false);
        this.errorType = new ClassType(null, List.of(), "Error", noTypeParams, throwableType, noInterfaces, noModifiers, false);

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
        this.nullType = new ClassType(null, List.of(), "Null", noTypeParams, null, noInterfaces, noModifiers, false);

        initializeBuiltinTypes();
    }

    private void initializeBuiltinTypes() {
        // Add primitive types
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
        types.put("Error", errorType);

        // Add quantum types
        types.put("qubit", new QuantumType(null, List.of(), QuantumTypeKind.QUBIT));
        types.put("qureg", new QuantumType(null, List.of(), QuantumTypeKind.QUREG));
        types.put("state", new QuantumType(null, List.of(), QuantumTypeKind.STATE));
    }

    public void define(String name, Type type) {
        if (name == null) throw new IllegalArgumentException("Name cannot be null");
        if (type == null) throw new IllegalArgumentException("Type cannot be null");
        variables.put(name, type);
    }

    public Type lookup(String name) {
        if (name == null) throw new IllegalArgumentException("Name cannot be null");

        Type type = variables.get(name);
        if (type != null) return type;

        if (type == null) {
            type = types.get(name);
        }

        if (type == null && parent != null) {
            type = parent.lookup(name);
        }

        return type;
    }

    public Type getQuantumRegisterType(int size) {
        return new QuantumType(null, List.of(), QuantumTypeKind.QUREG, size);
    }

    public Type getQuantumStateType(int numQubits) {
        return new QuantumType(null, List.of(), QuantumTypeKind.STATE, numQubits);
    }

    public Type getFunctionalInterfaceType(List<Parameter> parameters, Type returnType) {
        String name = "Function" + parameters.size();
        List<Type> typeArguments = new ArrayList<>();

        for (Parameter param : parameters) {
            typeArguments.add(param.getType());
        }
        typeArguments.add(returnType);

        Set<Modifier> modifiers = new HashSet<>();
        modifiers.add(Modifier.PUBLIC);
        modifiers.add(Modifier.ABSTRACT);

        return new ClassType(null, List.of(), name, typeArguments,
                (ClassType) getObjectType(), List.of(), modifiers, true);
    }

    public Map<String, Type> getTypes() {
        return Collections.unmodifiableMap(types);
    }

    public Map<String, Type> getVariables() {
        return Collections.unmodifiableMap(variables);
    }

    public Type getUnitType() {
        return unitType;
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

    public Type getNullType() {
        return nullType;
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

    public TypeEnvironment getParent() {
        return parent;
    }

    public boolean isDefined(String name) {
        if (variables.containsKey(name) || types.containsKey(name)) {
            return true;
        }
        return parent != null && parent.isDefined(name);
    }

    public TypeEnvironment getDefiningEnvironment(String name) {
        if (variables.containsKey(name) || types.containsKey(name)) {
            return this;
        }
        if (parent != null) {
            return parent.getDefiningEnvironment(name);
        }
        return null;
    }
}