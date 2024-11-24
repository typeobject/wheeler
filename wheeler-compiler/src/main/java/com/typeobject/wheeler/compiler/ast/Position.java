package com.typeobject.wheeler.compiler.ast;

// Position tracking for error reporting
public record Position(String sourceFile, int line, int column) {}
