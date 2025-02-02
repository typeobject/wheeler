// Defines all numeric literal formats
lexer grammar NumericLiterals;

// Integer literals with optional type suffixes
INTEGER_LITERAL
    : DecimalNumeral [lL]?         // Regular decimal numbers
    | HexNumeral [lL]?             // Hexadecimal numbers
    | BinaryNumeral [lL]?          // Binary numbers
    | OctalNumeral [lL]?           // Octal numbers
    ;

// Floating point literals with optional type suffixes
FLOAT_LITERAL
    : DecimalFloatingPoint         // Regular decimal float
    | HexadecimalFloatingPoint     // Hexadecimal float
    ;

// Fragment rules for numeric components
fragment DecimalNumeral
    : '0'                          // Single zero
    | [1-9] ([0-9_]* [0-9])?      // Non-zero with optional digits
    ;

fragment HexNumeral
    : '0' [xX] HexDigits          // Hex starting with 0x or 0X
    ;

fragment BinaryNumeral
    : '0' [bB] [01] ([01_]* [01])? // Binary starting with 0b or 0B
    ;

fragment OctalNumeral
    : '0' [0-7] ([0-7_]* [0-7])?   // Octal starting with 0
    ;

fragment HexDigits
    : HexDigit ([0-9a-fA-F_]* HexDigit)? // One or more hex digits
    ;

fragment HexDigit
    : [0-9a-fA-F]                  // Single hex digit
    ;

fragment DecimalFloatingPoint
    : Digits '.' Digits? ExponentPart? [fFdD]?     // 1.23, 1.23e10
    | '.' Digits ExponentPart? [fFdD]?             // .123
    | Digits ExponentPart [fFdD]?                  // 1e10
    | Digits [fFdD]                                // 1.0f
    ;

fragment HexadecimalFloatingPoint
    : '0' [xX] HexDigits? '.' HexDigits? BinaryExponent [fFdD]?
    ;

fragment Digits
    : [0-9] ([0-9_]* [0-9])?      // One or more decimal digits
    ;

fragment ExponentPart
    : [eE] [+-]? Digits           // Decimal exponent
    ;

fragment BinaryExponent
    : [pP] [+-]? Digits           // Binary exponent for hex float
    ;