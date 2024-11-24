package com.typeobject.wheeler.compiler.ast.classical.types;

import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.base.Type;
import java.util.List;

public final class ClassType extends ClassicalType {
    private final String name;
    private final List<Type> typeArguments;
    private final ClassType supertype;
    private final List<ClassType> interfaces;

    public ClassType(Position position, List<Annotation> annotations,
                     String name, List<Type> typeArguments,
                     ClassType supertype, List<ClassType> interfaces) {
        super(position, annotations, name, typeArguments, false);
        this.name = name;
        this.typeArguments = typeArguments;
        this.supertype = supertype;
        this.interfaces = interfaces;
    }

    public String getName() {
        return name;
    }

    public List<Type> getTypeArguments() {
        return typeArguments;
    }

    public ClassType getSupertype() {
        return supertype;
    }

    public List<ClassType> getInterfaces() {
        return interfaces;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitClassType(this);
    }
}