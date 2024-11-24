

// ImportDeclaration.java
package com.typeobject.wheeler.compiler.ast;

public class ImportDeclaration {
    private final String name;
    private final boolean isStatic;
    private final boolean isWildcard;

    public ImportDeclaration(String name, boolean isStatic, boolean isWildcard) {
        this.name = name;
        this.isStatic = isStatic;
        this.isWildcard = isWildcard;
    }

    public String getName() {
        return name;
    }

    public boolean isStatic() {
        return isStatic;
    }

    public boolean isWildcard() {
        return isWildcard;
    }
}