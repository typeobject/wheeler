package com.typeobject.wheeler.compiler.ast.base;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;

import java.util.List;

public abstract class Type extends Node {
    protected Type(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }

    public boolean isQubit() {
        return false;
    }

    public boolean isQuantum() {
        return false;
    }

    public boolean isClassical() {
        return false;
    }
}