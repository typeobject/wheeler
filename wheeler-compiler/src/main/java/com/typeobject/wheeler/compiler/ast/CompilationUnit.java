// CompilationUnit.java
package com.typeobject.wheeler.compiler.ast;

import com.typeobject.wheeler.compiler.ast.base.Declaration;

import java.util.ArrayList;
import java.util.List;

public final class CompilationUnit extends Node {
    private final String packageName;
    private final List<ImportDeclaration> imports;
    private final List<Declaration> declarations;

    public CompilationUnit(Position position, List<Annotation> annotations,
                           String packageName, List<ImportDeclaration> imports,
                           List<Declaration> declarations) {
        super(position, annotations);
        this.packageName = packageName;
        this.imports = imports != null ? imports : new ArrayList<>();
        this.declarations = declarations != null ? declarations : new ArrayList<>();
    }

    public String getPackage() {
        return packageName;
    }

    public List<ImportDeclaration> getImports() {
        return imports;
    }

    public List<Declaration> getDeclarations() {
        return declarations;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitCompilationUnit(this);
    }
}