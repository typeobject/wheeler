// Position.java
package com.typeobject.wheeler.compiler.ast;

public class Position {
    private final int line;
    private final int column;
    private final String source;

    public Position(int line, int column, String source) {
        this.line = line;
        this.column = column;
        this.source = source;
    }

    public int getLine() {
        return line;
    }

    public int getColumn() {
        return column;
    }

    public String getSource() {
        return source;
    }
}