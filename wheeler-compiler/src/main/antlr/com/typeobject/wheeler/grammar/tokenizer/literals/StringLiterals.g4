// Defines string and character literal formats
lexer grammar StringLiterals;

// String literals
STRING_LITERAL
    : '"' StringCharacter* '"'     // Regular string
    | '"""' MultiLineString '"""'   // Multi-line string
    ;

// Character literals
CHAR_LITERAL
    : '\'' SingleCharacter '\''     // Single character
    | '\'' EscapeSequence '\''      // Escaped character
    ;

// Fragment rules for string components
fragment StringCharacter
    : ~["\\\r\n]                   // Any non-special character
    | EscapeSequence               // Escaped character sequence
    ;

fragment MultiLineString
    : .*?                          // Any characters until """
    ;

fragment SingleCharacter
    : ~['\\\r\n]                   // Any non-special character
    ;

fragment EscapeSequence
    : '\\' [btnfr"'\\]            // Common escapes
    | OctalEscape                  // Octal escape
    | UnicodeEscape               // Unicode escape
    ;

fragment OctalEscape
    : '\\' [0-3] [0-7] [0-7]      // Octal escape sequence
    | '\\' [0-7] [0-7]
    | '\\' [0-7]
    ;

fragment UnicodeEscape
    : '\\' 'u'+ HexDigit HexDigit HexDigit HexDigit  // Unicode escape
    ;