package com.typeobject.wheeler.compiler.ast;

import java.nio.file.Path;

public final class SourcePosition {
    private final Path source;
    private final int line;
    private final int column;
    private final int offset;
    private final int length;

    public SourcePosition(Path source, int line, int column, int offset, int length) {
        this.source = source;
        this.line = line;
        this.column = column;
        this.offset = offset;
        this.length = length;
    }

    public Path getSource() {
        return source;
    }

    public int getLine() {
        return line;
    }

    public int getColumn() {
        return column;
    }

    public int getOffset() {
        return offset;
    }

    public int getLength() {
        return length;
    }

    @Override
    public String toString() {
        return String.format("%s:%d:%d", source.getFileName(), line, column);
    }
}