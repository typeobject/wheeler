package com.typeobject.wheeler.compiler.ast.classical.declarations;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.base.Expression;

public final class FieldDeclaration extends Declaration {
    private final Type type;
    private final Expression initializer;

    public FieldDeclaration(Position position, List<Annotation> annotations,
                            Type type, String name, Expression initializer) {
        super(position, annotations, List.of(), name);
        this.type = type;
        this.initializer = initializer;
    }

    public Type getType() {
        return type;
    }

    public Expression getInitializer() {
        return initializer;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitFieldDeclaration(this);
    }
}