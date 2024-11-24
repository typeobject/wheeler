// WheelerOperators.g4
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
ELLIPSIS: '...';
AT: '@';
DOUBLECOLON: '::';
PIPE: '|';              // Added for pattern matching
UNDERSCORE: '_';        // Added for pattern matching
AMPERSAND: '&';         // Added for type bounds

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
TENSOR: '⊗';
CONJUGATE: '†';
MUL: '*';
DIV: '/';
ADD: '+';
SUB: '-';

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
URSHIFT: '>>>';

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
URSHIFT_ASSIGN: '>>>=';