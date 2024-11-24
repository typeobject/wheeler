package com.typeobject.wheeler.compiler.ast.hybrid;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;

public abstract sealed class HybridStatement extends Statement
        permits HybridBlock, ClassicalToQuantumConversion, QuantumToClassicalConversion,
        HybridIfStatement, HybridWhileStatement {

    protected HybridStatement(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}