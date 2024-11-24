package com.typeobject.wheeler.compiler.ast.classical.expressions;

public enum BinaryOperator {
    // Arithmetic
    ADD("+"),
    SUBTRACT("-"),
    MULTIPLY("*"),
    DIVIDE("/"),
    MODULO("%"),

    // Bitwise
    AND("&"),
    OR("|"),
    XOR("^"),
    LEFT_SHIFT("<<"),
    RIGHT_SHIFT(">>"),
    UNSIGNED_RIGHT_SHIFT(">>>"),

    // Logical
    LOGICAL_AND("&&"),
    LOGICAL_OR("||"),

    // Comparison
    EQUAL("=="),
    NOT_EQUAL("!="),
    LESS_THAN("<"),
    LESS_EQUAL("<="),
    GREATER_THAN(">"),
    GREATER_EQUAL(">=");

    private final String symbol;

    BinaryOperator(String symbol) {
        this.symbol = symbol;
    }

    public String getSymbol() {
        return symbol;
    }
}
