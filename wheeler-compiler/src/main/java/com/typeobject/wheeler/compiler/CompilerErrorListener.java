package com.typeobject.wheeler.compiler;

import org.antlr.v4.runtime.BaseErrorListener;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.Recognizer;

public class CompilerErrorListener extends BaseErrorListener {
    private final ErrorReporter errorReporter;

    public CompilerErrorListener(ErrorReporter errorReporter) {
        this.errorReporter = errorReporter;
    }

    @Override
    public void syntaxError(
            Recognizer<?, ?> recognizer,
            Object offendingSymbol,
            int line,
            int charPositionInLine,
            String msg,
            RecognitionException e) {
        errorReporter.reportError(msg, line, charPositionInLine);
    }
}