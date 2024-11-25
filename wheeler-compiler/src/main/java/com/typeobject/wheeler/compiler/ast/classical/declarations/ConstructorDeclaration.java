package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import java.util.List;

public final class ConstructorDeclaration extends Declaration {
    private final List<Parameter> parameters;
    private final Block body;

    public ConstructorDeclaration(Position position, List<Annotation> annotations,
                                  List<Parameter> parameters, Block body, String name) {
        super(position, annotations, List.of(), name);
        this.parameters = parameters;
        this.body = body;
    }

    public List<Parameter> getParameters() {
        return parameters;
    }

    public Block getBody() {
        return body;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitConstructorDeclaration(this);
    }
}