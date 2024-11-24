// Annotation.java
package com.typeobject.wheeler.compiler.ast;

import java.util.List;

public class Annotation {
    private final String name;
    private final List<String> parameters;

    public Annotation(String name, List<String> parameters) {
        this.name = name;
        this.parameters = parameters;
    }

    public String getName() {
        return name;
    }

    public List<String> getParameters() {
        return parameters;
    }
}