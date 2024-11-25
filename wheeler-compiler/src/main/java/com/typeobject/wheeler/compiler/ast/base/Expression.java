package com.typeobject.wheeler.compiler.ast.base;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;
import java.util.List;

public abstract class Expression extends Node {
    private Type type;

    protected Expression(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }

    public Type getType() {
        return type;
    }

    public void setType(Type type) {
        this.type = type;
    }
}