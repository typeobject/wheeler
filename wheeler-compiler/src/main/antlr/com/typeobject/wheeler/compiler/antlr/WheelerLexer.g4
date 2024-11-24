lexer grammar WheelerLexer;

import WheelerKeywords, WheelerOperators, WheelerTypes;

// Whitespace and comments
WS: [ \t\r\n\u000C]+ -> skip;
LINE_COMMENT: '//' ~[\r\n]* -> skip;
BLOCK_COMMENT: '/*' .*? '*/' -> skip;

// Classical literals
INTEGER_LITERAL
    : [0-9]+ [lL]?
    | '0x' [0-9a-fA-F]+ [lL]?
    | '0b' [01]+ [lL]?
    ;

FLOAT_LITERAL
    : [0-9]+ '.' [0-9]* ExponentPart? [fFdD]?
    | '.' [0-9]+ ExponentPart? [fFdD]?
    | [0-9]+ ExponentPart [fFdD]?
    ;

BOOL_LITERAL: 'true' | 'false';
CHAR_LITERAL: '\'' (~['\\\r\n] | EscapeSequence) '\'';
STRING_LITERAL: '"' (~["\\\r\n] | EscapeSequence)* '"';
NULL_LITERAL: 'null';

// Quantum literals
QUBIT_KET: '|' ([01] | '+' | '-') '⟩';
QUBIT_BRA: '⟨' ([01] | '+' | '-') '|';
STATE_LITERAL: StateCoefficient? QUBIT_KET;
MATRIX_LITERAL: '[[' ComplexNumber (',' ComplexNumber)* ']]';

// Identifiers
IDENTIFIER: Letter LetterOrDigit*;

// Complex numbers for quantum states
ComplexNumber
    : [0-9]+ ('.' [0-9]*)?
    | [0-9]+ ('.' [0-9]*)? 'i'
    | [0-9]+ ('.' [0-9]*)? [+-] [0-9]+ ('.' [0-9]*)? 'i'
    ;

// State coefficients for quantum states
StateCoefficient
    : ('√'? [0-9]+ '/' [0-9]+)
    | ComplexNumber
    ;

// Fragments
fragment Letter: [a-zA-Z$_];
fragment LetterOrDigit: [a-zA-Z0-9$_];
fragment ExponentPart: [eE] [+-]? [0-9]+;
fragment EscapeSequence
    : '\\' [btnfr"'\\]
    | OctalEscape
    | UnicodeEscape
    ;
fragment OctalEscape: '\\' [0-3]? [0-7]? [0-7];
fragment UnicodeEscape: '\\' 'u'+ HexDigit HexDigit HexDigit HexDigit;
fragment HexDigit: [0-9a-fA-F];