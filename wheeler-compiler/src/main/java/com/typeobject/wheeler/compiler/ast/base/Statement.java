package com.typeobject.wheeler.compiler.ast.base;

import com.typeobject.wheeler.compiler.ast.Node;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.quantum.statements.QuantumStatement;

// Statements
public abstract sealed class Statement extends Node
    permits Block, IfStatement, WhileStatement, QuantumStatement, HybridStatement /* ... */ {}
