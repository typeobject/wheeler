package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Declaration;

import java.util.List;

public final class PackageDeclaration extends Declaration {
    private final String packageName;

    public PackageDeclaration(Position position, List<Annotation> annotations, String packageName) {
        super(position, annotations, List.of(), packageName);
        this.packageName = packageName;
    }

    public String getPackageName() {
        return packageName;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitPackageDeclaration(this);
    }
}