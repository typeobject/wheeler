// Statement.java
package com.typeobject.wheeler.compiler.ast.base;

import java.util.List;
import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.classical.statements.IfStatement;
import com.typeobject.wheeler.compiler.ast.classical.statements.WhileStatement;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumStatement;
import com.typeobject.wheeler.compiler.ast.hybrid.HybridStatement;
import com.typeobject.wheeler.compiler.ast.memory.CleanBlock;
import com.typeobject.wheeler.compiler.ast.memory.UncomputeBlock;

public abstract sealed class Statement extends Node
        permits Block, IfStatement, WhileStatement, QuantumStatement, HybridStatement,
        CleanBlock, UncomputeBlock {

    protected Statement(Position position, List<Annotation> annotations) {
        super(position, annotations);
    }
}