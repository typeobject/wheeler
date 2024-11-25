package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.ast.Position;

import java.util.ArrayList;
import java.util.List;

public class ErrorReporter {
    private final List<CompilerError> errors = new ArrayList<>();
    private final List<CompilerError> warnings = new ArrayList<>();

    public void report(String message, Position position) {
        if (position != null) {
            errors.add(new CompilerError(message, position.getLine(), position.getColumn()));
        } else {
            errors.add(new CompilerError(message));
        }
    }

    public void reportError(String message, int line, int column) {
        errors.add(new CompilerError(message, line, column));
    }

    public void warn(String message, Position position) {
        if (position != null) {
            warnings.add(new CompilerError(message, position.getLine(), position.getColumn()));
        } else {
            warnings.add(new CompilerError(message));
        }
    }

    public boolean hasErrors() {
        return !errors.isEmpty();
    }

    public List<CompilerError> getErrors() {
        return errors;
    }

    public List<CompilerError> getWarnings() {
        return warnings;
    }
}