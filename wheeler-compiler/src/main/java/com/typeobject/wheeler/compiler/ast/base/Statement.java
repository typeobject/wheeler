package com.typeobject.wheeler.compiler.ast.base;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;

public abstract class Statement extends Node {
    protected Statement(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}