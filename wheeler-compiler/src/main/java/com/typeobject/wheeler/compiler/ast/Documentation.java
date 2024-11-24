package com.typeobject.wheeler.compiler.ast;

import java.util.List;

public final class Documentation extends Node {
    private final String text;
    private final List<DocumentationTag> tags;

    public Documentation(Position position, List<Annotation> annotations,
                         String text, List<DocumentationTag> tags) {
        super(position, annotations);
        this.text = text;
        this.tags = tags;
    }

    public String getText() {
        return text;
    }

    public List<DocumentationTag> getTags() {
        return tags;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitDocumentation(this);
    }

    public static class DocumentationTag {
        private final String name;
        private final String value;

        public DocumentationTag(String name, String value) {
            this.name = name;
            this.value = value;
        }

        public String getName() {
            return name;
        }

        public String getValue() {
            return value;
        }
    }
}