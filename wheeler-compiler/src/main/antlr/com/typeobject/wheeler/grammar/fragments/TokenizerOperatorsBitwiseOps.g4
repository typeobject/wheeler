// Defines bitwise manipulation operators
lexer grammar TokenizerOperatorsBitwiseOps;

// Bitwise operations
BIT_AND     : '&';               // Bitwise AND
BIT_OR      : '|';               // Bitwise OR
BIT_XOR     : '^';               // Bitwise XOR
BIT_NOT     : '~';               // Bitwise NOT

// Bit shifting
LSHIFT      : '<<';              // Left shift
RSHIFT      : '>>';              // Right shift (signed)
URSHIFT     : '>>>';             // Unsigned right shift