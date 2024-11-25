package com.typeobject.wheeler.compiler;

import org.antlr.v4.runtime.BaseErrorListener;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.Recognizer;
import org.antlr.v4.runtime.Token;

public class CompilerErrorListener extends BaseErrorListener {
    private final ErrorReporter errorReporter;
    private boolean hasCriticalErrors = false;

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

        String location = "";
        if (offendingSymbol instanceof Token) {
            Token token = (Token) offendingSymbol;
            location = String.format(" at token '%s'", token.getText());
        }

        String fullMessage = String.format("Line %d:%d%s - %s",
                line, charPositionInLine, location, msg);

        System.err.println(fullMessage);

        // Report all errors but only mark critical ones
        errorReporter.reportError(msg, line, charPositionInLine);

        if (e != null && (
                e.getMessage() != null ||  // Parser exceptions
                        msg.contains("missing") ||  // Missing required elements
                        msg.contains("no viable alternative") || // Unrecognized syntax
                        msg.contains("extraneous input") // Unexpected tokens
        )) {
            hasCriticalErrors = true;
        }
    }

    public boolean hasCriticalErrors() {
        return hasCriticalErrors;
    }
}