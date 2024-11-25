package com.typeobject.wheeler.compiler.analysis;

import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.types.ArrayType;
import com.typeobject.wheeler.compiler.ast.classical.types.ClassType;
import com.typeobject.wheeler.compiler.ast.classical.types.PrimitiveType;

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

    // Define a type in the environment
    public void define(String name, Type type) {
        if (name == null) throw new IllegalArgumentException("Name cannot be null");
        if (type == null) throw new IllegalArgumentException("Type cannot be null");
        variables.put(name, type);
    }

    // Look up a type in the environment
    public Type lookup(String name) {
        if (name == null) throw new IllegalArgumentException("Name cannot be null");

        Type type = variables.get(name);
        if (type != null) return type;

        if (parent != null) {
            return parent.lookup(name);
        }

        return null;
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

    public Type getUnitType() {
        return unitType;
    }

    // Initialize built-in types in the type environment
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
        types.put("Error", errorType);
    }

    // Type compatibility checking
    public boolean isAssignable(Type target, Type source) {
        if (target == null || source == null) return false;
        if (target.equals(source)) return true;

        // Handle null type
        if (source.equals(nullType)) {
            return !isPrimitive(target);
        }

        if (target instanceof ClassType && source instanceof ClassType) {
            return isClassAssignable((ClassType) target, (ClassType) source);
        }

        if (target instanceof ArrayType targetArray && source instanceof ArrayType sourceArray) {
            return targetArray.getDimensions() == sourceArray.getDimensions()
                    && isAssignable(targetArray.getElementType(), sourceArray.getElementType());
        }

        return false;
    }

    private boolean isPrimitive(Type type) {
        return type instanceof PrimitiveType;
    }

    private boolean isClassAssignable(ClassType target, ClassType source) {
        if (target.equals(source)) return true;

        // Check superclass chain
        ClassType current = source;
        while (current.getSupertype() != null) {
            if (target.equals(current.getSupertype())) return true;
            current = current.getSupertype();
        }

        // Check interfaces
        for (ClassType iface : source.getInterfaces()) {
            if (isClassAssignable(target, iface)) return true;
        }

        return false;
    }
}