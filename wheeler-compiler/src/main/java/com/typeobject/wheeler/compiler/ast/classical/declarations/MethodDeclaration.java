package com.typeobject.wheeler.compiler.ast.classical.declarations;

import com.typeobject.wheeler.compiler.ast.Annotation;
import com.typeobject.wheeler.compiler.ast.ComputationType;
import com.typeobject.wheeler.compiler.ast.Modifier;
import com.typeobject.wheeler.compiler.ast.NodeVisitor;
import com.typeobject.wheeler.compiler.ast.Position;
import com.typeobject.wheeler.compiler.ast.base.Declaration;
import com.typeobject.wheeler.compiler.ast.base.Type;
import com.typeobject.wheeler.compiler.ast.classical.Block;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Parameter;
import com.typeobject.wheeler.compiler.ast.quantum.declarations.Reversible;

import java.util.ArrayList;
import java.util.List;

public final class MethodDeclaration extends Declaration implements Reversible {
    private final Type returnType;
    private final List<Parameter> parameters;
    private final Block body;
    private final ComputationType computationType;
    private final boolean isPure;
    private final boolean isRev;

    public MethodDeclaration(Position position, List<Annotation> annotations, List<Modifier> modifiers,
                             String name, Type returnType, List<Parameter> parameters,
                             Block body, ComputationType computationType,
                             boolean isPure, boolean isRev) {
        super(position, annotations, modifiers, name);
        this.returnType = returnType;
        this.parameters = parameters;
        this.body = body;
        this.computationType = computationType;
        this.isPure = isPure;
        this.isRev = isRev;
    }

    @Override
    public boolean isReversible() {
        return isRev || isPure;
    }

    @Override
    public <T> T accept(NodeVisitor<T> visitor) {
        return visitor.visitMethodDeclaration(this);
    }

    public static class Builder {
        private Position position;
        private final List<Annotation> annotations = new ArrayList<>();
        private final List<Modifier> modifiers = new ArrayList<>();
        private final String name;
        private Type returnType;
        private final List<Parameter> parameters = new ArrayList<>();
        private Block body;
        private ComputationType computationType = ComputationType.CLASSICAL;
        private boolean isPure;
        private boolean isRev;

        public Builder(String name) {
            this.name = name;
        }

        public Builder position(Position position) {
            this.position = position;
            return this;
        }

        public Builder addModifier(Modifier modifier) {
            modifiers.add(modifier);
            return this;
        }

        public Builder returnType(Type returnType) {
            this.returnType = returnType;
            return this;
        }

        public Builder addParameter(Parameter parameter) {
            parameters.add(parameter);
            return this;
        }

        public Builder body(Block body) {
            this.body = body;
            return this;
        }

        public Builder computationType(ComputationType computationType) {
            this.computationType = computationType;
            return this;
        }

        public Builder pure(boolean isPure) {
            this.isPure = isPure;
            return this;
        }

        public Builder reversible(boolean isRev) {
            this.isRev = isRev;
            return this;
        }

        public MethodDeclaration build() {
            return new MethodDeclaration(position, annotations, modifiers, name,
                    returnType, parameters, body, computationType,
                    isPure, isRev);
        }
    }
}
