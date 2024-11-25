package com.typeobject.wheeler.compiler.ast.classical.statements;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Expression;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.List;

public final class VariableDeclaration extends Statement {
    private final Type type;
    private final String name;
    private final Expression initializer;

    public VariableDeclaration(Position position, List<Annotation> annotations,
                               Type type, String name, Expression initializer) {
        super(position, annotations);
        this.type = type;
        this.name = name;
        this.initializer = initializer;
    }

    public Type getType() {
        return type;
    }

    public String getName() {
        return name;
    }

    public Expression getInitializer() {
        return initializer;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitVariableDeclaration(this);
    }
}