package com.typeobject.wheeler.compiler.antlr;

import static org.junit.jupiter.api.Assertions.*;

import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.Token;
import org.junit.jupiter.api.Test;

class WheelerLexerTest {

    @Test
    void testClassicalLiterals() {
        String input = """
            42
            3.14
            "hello"
            true
            false
            'c'
            null
            """;
        WheelerLexer lexer = new WheelerLexer(CharStreams.fromString(input));

        Token token = lexer.nextToken();
        assertEquals(WheelerLexer.INTEGER_LITERAL, token.getType(), "Integer type 42");
        assertEquals("42", token.getText(), "Integer literal 42");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.FLOAT_LITERAL, token.getType(), "Float type 3.14");
        assertEquals("3.14", token.getText(), "Float literal 3.14");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.STRING_LITERAL, token.getType(), "String type hello");
        assertEquals("\"hello\"", token.getText(), "String literal hello");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.BOOL_LITERAL, token.getType(), "Boolean type true");
        assertEquals("true", token.getText(), "Boolean literal true");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.BOOL_LITERAL, token.getType(), "Boolean type false");
        assertEquals("false", token.getText(), "Boolean literal false");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.CHAR_LITERAL, token.getType(), "Character type 'c'");
        assertEquals("'c'", token.getText(), "Character literal 'c'");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.NULL_LITERAL, token.getType(), "Null type null");
        assertEquals("null", token.getText(), "Null literal null");
    }

    @Test
    void testQuantumLiterals() {
        String input = """
            |0⟩
            |1⟩
            |+⟩
            |-⟩
            ⟨0|
            ⟨1|
            [[1, 0, 0, 1]]
            """;
        WheelerLexer lexer = new WheelerLexer(CharStreams.fromString(input));

        Token token = lexer.nextToken();
        assertEquals(WheelerLexer.QUBIT_KET, token.getType(), "qubit ket type |0⟩");
        assertEquals("|0⟩", token.getText(), "qubit ket literal |0⟩");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.QUBIT_KET, token.getType(), "qubit ket type |1⟩");
        assertEquals("|1⟩", token.getText(), "qubit ket literal |1⟩");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.QUBIT_KET, token.getType(), "qubit ket type |+⟩");
        assertEquals("|+⟩", token.getText(), "qubit ket literal |+⟩");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.QUBIT_KET, token.getType(), "qubit ket type |-⟩");
        assertEquals("|-⟩", token.getText(), "qubit ket literal |-⟩");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.QUBIT_BRA, token.getType(), "qubit bra type ⟨0|");
        assertEquals("⟨0|", token.getText(), "qubit bra literal ⟨0|");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.QUBIT_BRA, token.getType(), "qubit bra type ⟨1|");
        assertEquals("⟨1|", token.getText(), "qubit bra literal ⟨1|");

        token = lexer.nextToken();
        assertEquals(WheelerLexer.MATRIX_LITERAL, token.getType(), "matrix type [[1, 0, 0, 1]]");
        assertEquals("[[1, 0, 0, 1]]", token.getText(), "matrix literal [[1, 0, 0, 1]]");
    }

    @Test
    void testOperators() {
        String input = "+-*/ == != <= >= && || ⊗ †";
        WheelerLexer lexer = new WheelerLexer(CharStreams.fromString(input));

        assertEquals(WheelerLexer.ADD, lexer.nextToken().getType(), "Addition operator +");
        assertEquals(WheelerLexer.SUB, lexer.nextToken().getType(), "Subtraction operator -");
        assertEquals(WheelerLexer.MUL, lexer.nextToken().getType(), "Multiplication operator *");
        assertEquals(WheelerLexer.DIV, lexer.nextToken().getType(), "Division operator /");
        assertEquals(WheelerLexer.EQUAL, lexer.nextToken().getType(), "Equality operator ==");
        assertEquals(WheelerLexer.NOTEQUAL, lexer.nextToken().getType(), "Inequality operator !=");
        assertEquals(WheelerLexer.LE, lexer.nextToken().getType(), "Less than or equal operator <=");
        assertEquals(WheelerLexer.GE, lexer.nextToken().getType(), "Greater than or equal operator >=");
        assertEquals(WheelerLexer.AND, lexer.nextToken().getType(), "Logical AND operator &&");
        assertEquals(WheelerLexer.OR, lexer.nextToken().getType(), "Logical OR operator ||");
        assertEquals(WheelerLexer.TENSOR, lexer.nextToken().getType(), "Tensor product operator ⊗");
        assertEquals(WheelerLexer.CONJUGATE, lexer.nextToken().getType(), "Conjugate operator †");
    }
}