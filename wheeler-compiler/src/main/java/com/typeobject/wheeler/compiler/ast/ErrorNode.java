package com.typeobject.wheeler.compiler.ast;

import java.util.List;

public final class ErrorNode extends Node {
    private final String message;
    private final Throwable cause;

    public ErrorNode(Position position, List<Annotation> annotations,
                     String message, Throwable cause) {
        super(position, annotations);
        this.message = message;
        this.cause = cause;
    }

    public String getMessage() {
        return message;
    }

    public Throwable getCause() {
        return cause;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitErrorNode(this);
    }
}