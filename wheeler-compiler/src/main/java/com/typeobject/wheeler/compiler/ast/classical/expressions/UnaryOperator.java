package com.typeobject.wheeler.compiler.ast.classical.expressions;

public enum UnaryOperator {
    // Arithmetic
    PLUS("+"),
    MINUS("-"),

    // Increment/Decrement
    INCREMENT("++"),
    DECREMENT("--"),

    // Logical
    NOT("!"),

    // Bitwise
    BITWISE_COMPLEMENT("~");

    private final String symbol;

    UnaryOperator(String symbol) {
        this.symbol = symbol;
    }

    public String getSymbol() {
        return symbol;
    }
}