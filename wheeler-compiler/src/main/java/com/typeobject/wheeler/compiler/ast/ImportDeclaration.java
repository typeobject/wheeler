// ImportDeclaration.java
package com.typeobject.wheeler.compiler.ast;

import java.util.List;

public class ImportDeclaration extends Node {
    private final String name;
    private final boolean isStatic;
    private final boolean isWildcard;

    public ImportDeclaration(Position position, List<Annotation> annotations, String name, boolean isStatic, boolean isWildcard) {
        super(position, annotations);

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

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitImportDeclaration(this);
    }
}