package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import java.util.List;

public final class MethodDeclaration extends Declaration {
    private final Type returnType;
    private final List<Parameter> parameters;
    private final Block body;
    private final boolean isPure;
    private final boolean isRev;

    public MethodDeclaration(Position position, List<Annotation> annotations,
                             List<Modifier> modifiers, String name, Type returnType,
                             List<Parameter> parameters, Block body,
                             boolean isPure, boolean isRev) {
        super(position, annotations, modifiers, name);
        this.returnType = returnType;
        this.parameters = parameters;
        this.body = body;
        this.isPure = isPure;
        this.isRev = isRev;
    }

    public Type getReturnType() {
        return returnType;
    }

    public List<Parameter> getParameters() {
        return parameters;
    }

    public Block getBody() {
        return body;
    }

    public boolean isPure() {
        return isPure;
    }

    public boolean isRev() {
        return isRev;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitMethodDeclaration(this);
    }
}