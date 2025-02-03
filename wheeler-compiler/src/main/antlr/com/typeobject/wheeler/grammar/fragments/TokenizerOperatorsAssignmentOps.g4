// Defines assignment operators
lexer grammar TokenizerOperatorsAssignmentOps;

// Basic assignment
ASSIGN      : '=';               // Simple assignment

// Compound assignments
ADD_ASSIGN  : '+=';              // Add and assign
SUB_ASSIGN  : '-=';              // Subtract and assign
MUL_ASSIGN  : '*=';              // Multiply and assign
DIV_ASSIGN  : '/=';              // Divide and assign
MOD_ASSIGN  : '%=';              // Modulo and assign
AND_ASSIGN  : '&=';              // Bitwise AND and assign
OR_ASSIGN   : '|=';              // Bitwise OR and assign
XOR_ASSIGN  : '^=';              // Bitwise XOR and assign
LSHIFT_ASSIGN : '<<=';           // Left shift and assign
RSHIFT_ASSIGN : '>>=';           // Right shift and assign
URSHIFT_ASSIGN : '>>>=';         // Unsigned right shift and assign