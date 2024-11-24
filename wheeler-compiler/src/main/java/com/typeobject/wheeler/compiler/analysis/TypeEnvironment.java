// TypeEnvironment.java
package com.typeobject.wheeler.compiler.analysis;

import java.util.HashMap;
import java.util.Map;
import com.typeobject.wheeler.compiler.ast.base.Type;

public class TypeEnvironment {
    private final Map<String, Type> types = new HashMap<>();
    private final TypeEnvironment parent;
    private final Type unitType;

    public TypeEnvironment(TypeEnvironment parent, Type unitType) {
        this.parent = parent;
        this.unitType = unitType;
    }

    public void define(String name, Type type) {
        types.put(name, type);
    }

    public Type lookup(String name) {
        Type type = types.get(name);
        if (type != null) return type;
        if (parent != null) return parent.lookup(name);
        return null;
    }

    public Type getUnitType() {
        return unitType;
    }
}