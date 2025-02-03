// Defines string and character literal formats
// ===================================================================
// StringLiterals.g4
// Defines string and character literal tokens
// ===================================================================

lexer grammar StringLiterals;

// String literal (handles escapes)
STRING_LITERAL
    : '"'
      ( EscapeSequence
      | ~["\\\r\n]            // Any char except " \ CR LF
      )*
      '"'
    ;

// Character literal
CHAR_LITERAL
    : '\''
      ( EscapeSequence
      | ~['\\\r\n]           // Any char except ' \ CR LF
      )
      '\''
    ;

// Raw string literal (no escape processing)
RAW_STRING_LITERAL
    : 'r"'
      .*?
      '"'
    ;

// Escape sequences in strings
fragment EscapeSequence
    : '\\' [btnfr"'\\]       // Simple escapes
    | OctalEscape           // Octal escapes
    | UnicodeEscape         // Unicode escapes
    ;

// Octal escape sequence
fragment OctalEscape
    : '\\' [0-3] [0-7] [0-7]
    | '\\' [0-7] [0-7]
    | '\\' [0-7]
    ;

// Unicode escape sequence
fragment UnicodeEscape
    : '\\' 'u'+ HexDigit HexDigit HexDigit HexDigit
    ;

// Hexadecimal digit
fragment HexDigit
    : [0-9a-fA-F]
    ;