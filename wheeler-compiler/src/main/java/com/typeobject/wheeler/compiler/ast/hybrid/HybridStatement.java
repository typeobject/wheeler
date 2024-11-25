package com.typeobject.wheeler.compiler.ast.hybrid;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Statement;
import java.util.List;

public abstract sealed class HybridStatement extends Statement
        permits HybridBlock, ClassicalToQuantumConversion, QuantumToClassicalConversion,
        HybridIfStatement, HybridWhileStatement {

    protected HybridStatement(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}