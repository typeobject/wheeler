package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.ComputationType;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class ClassDeclaration extends Declaration {
    private final Type superClass;
    private final List<Type> interfaces;
    private final List<Declaration> members;
    private final ComputationType computationType;

    private ClassDeclaration(
            Position position,
            List<Annotation> annotations,
            List<Modifier> modifiers,
            String name,
            Type superClass,
            List<Type> interfaces,
            List<Declaration> members,
            ComputationType computationType) {
        super(position, annotations, modifiers, name);
        this.superClass = superClass;
        this.interfaces = new ArrayList<>(interfaces);
        this.members = new ArrayList<>(members);
        this.computationType = computationType;
    }

    public Type getSuperClass() {
        return superClass;
    }

    public List<Type> getInterfaces() {
        return Collections.unmodifiableList(interfaces);
    }

    public List<Declaration> getMembers() {
        return Collections.unmodifiableList(members);
    }

    public boolean isQuantum() {
        return computationType == ComputationType.QUANTUM;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitClassDeclaration(this);
    }

    public static class Builder {
        private final List<Annotation> annotations = new ArrayList<>();
        private final List<Modifier> modifiers = new ArrayList<>();
        private final String name;
        private final List<Type> interfaces = new ArrayList<>();
        private final List<Declaration> members = new ArrayList<>();
        private Position position;
        private Type superClass;
        private ComputationType computationType = ComputationType.CLASSICAL;

        public Builder(String name) {
            this.name = name;
        }

        public Builder position(Position position) {
            this.position = position;
            return this;
        }

        public Builder addAnnotation(Annotation annotation) {
            annotations.add(annotation);
            return this;
        }

        public Builder addModifier(Modifier modifier) {
            modifiers.add(modifier);
            return this;
        }

        public Builder superClass(Type superClass) {
            this.superClass = superClass;
            return this;
        }

        public Builder addInterface(Type interfaceType) {
            interfaces.add(interfaceType);
            return this;
        }

        public Builder addMember(Declaration member) {
            members.add(member);
            return this;
        }

        public Builder computationType(ComputationType computationType) {
            this.computationType = computationType;
            return this;
        }

        public ClassDeclaration build() {
            return new ClassDeclaration(
                    position,
                    annotations,
                    modifiers,
                    name,
                    superClass,
                    interfaces,
                    members,
                    computationType
            );
        }
    }
}