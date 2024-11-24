package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import java.util.List;

public final class PrimitiveType extends ClassicalType {
    public enum Kind {
        BOOLEAN,
        BYTE,
        SHORT,
        INT,
        LONG,
        FLOAT,
        DOUBLE,
        CHAR,
        VOID
    }

    private final Kind kind;

    public PrimitiveType(Position position, List<Annotation> annotations, Kind kind) {
        super(position, annotations, kind.name().toLowerCase(), List.of(), true);
        this.kind = kind;
    }

    public Kind getKind() {
        return kind;
    }

    @Override
    public boolean isNumeric() {
        return kind != Kind.BOOLEAN && kind != Kind.VOID;
    }

    @Override
    public boolean isIntegral() {
        return kind == Kind.BYTE || kind == Kind.SHORT || kind == Kind.INT ||
                kind == Kind.LONG || kind == Kind.CHAR;
    }

    @Override
    public boolean isBoolean() {
        return kind == Kind.BOOLEAN;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitPrimitiveType(this);
    }
}