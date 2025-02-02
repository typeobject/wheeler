// Defines basic data types in Wheeler
lexer grammar PrimitiveTypes;

// Integer types
BYTE        : 'byte';            // 8-bit signed integer
SHORT       : 'short';           // 16-bit signed integer
INT         : 'int';             // 32-bit signed integer
LONG        : 'long';            // 64-bit signed integer

// Floating point types
FLOAT       : 'float';           // 32-bit floating point
DOUBLE      : 'double';          // 64-bit floating point

// Other primitives
BOOLEAN     : 'boolean';         // True/false value
CHAR        : 'char';            // 16-bit Unicode character
VOID        : 'void';            // No type/return value

// Special types
UNIT        : 'unit';            // Single value type
NEVER       : 'never';           // Bottom type (no values)