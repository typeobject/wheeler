package com.typeobject.wheeler.compiler.ast;

import java.util.List;

public final class CommentNode extends Node {
    private final String text;
    private final boolean isDocComment;

    public CommentNode(Position position, List<Annotation> annotations,
                       String text, boolean isDocComment) {
        super(position, annotations);
        this.text = text;
        this.isDocComment = isDocComment;
    }

    public String getText() {
        return text;
    }

    public boolean isDocComment() {
        return isDocComment;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitComment(this);
    }
}