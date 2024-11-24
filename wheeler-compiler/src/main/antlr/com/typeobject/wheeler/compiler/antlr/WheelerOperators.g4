lexer grammar WheelerOperators;

@header {
package com.typeobject.wheeler.compiler.antlr;
}

// Separators
LPAREN: '(';
RPAREN: ')';
LBRACE: '{';
RBRACE: '}';
LBRACK: '[';
RBRACK: ']';
SEMI: ';';
COMMA: ',';
DOT: '.';

// Operators
ASSIGN: '=';
GT: '>';
LT: '<';
BANG: '!';
TILDE: '~';
QUESTION: '?';
COLON: ':';
ARROW: '->';
DOUBLE_ARROW: '=>';
TENSOR: '⊗';        // Quantum tensor product
CONJUGATE: '†';     // Quantum conjugate

// Comparison
EQUAL: '==';
LE: '<=';
GE: '>=';
NOTEQUAL: '!=';

// Logical
AND: '&&';
OR: '||';

// Bitwise
BITAND: '&';
BITOR: '|';
CARET: '^';
MOD: '%';
LSHIFT: '<<';
RSHIFT: '>>';

// Arithmetic
ADD: '+';
SUB: '-';
MUL: '*';
DIV: '/';

// Increment/decrement
INC: '++';
DEC: '--';

// Compound assignment
ADD_ASSIGN: '+=';
SUB_ASSIGN: '-=';
MUL_ASSIGN: '*=';
DIV_ASSIGN: '/=';
AND_ASSIGN: '&=';
OR_ASSIGN: '|=';
XOR_ASSIGN: '^=';
MOD_ASSIGN: '%=';
LSHIFT_ASSIGN: '<<=';
RSHIFT_ASSIGN: '>>=';