package com.typeobject.wheeler.compiler.ast.base;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;
import java.util.List;

public abstract class Statement extends Node {
    protected Statement(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}