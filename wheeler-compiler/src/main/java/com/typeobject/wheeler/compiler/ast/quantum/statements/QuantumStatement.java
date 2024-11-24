// QuantumStatement.java
package com.typeobject.wheeler.compiler.ast.quantum.statements;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.base.Statement;

public abstract sealed class QuantumStatement extends Statement
        permits QuantumBlock, QuantumGateApplication, QuantumMeasurement,
        QuantumStatePreparation, QuantumIfStatement, QuantumWhileStatement {

    protected QuantumStatement(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}