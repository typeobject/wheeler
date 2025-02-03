// Defines boolean literal values
lexer grammar BooleanLiterals;

// Boolean literals
BOOLEAN_LITERAL
    : 'true'                       // True value
    | 'false'                      // False value
    ;

// Null literal
NULL_LITERAL
    : 'null'                       // Null reference
    ;