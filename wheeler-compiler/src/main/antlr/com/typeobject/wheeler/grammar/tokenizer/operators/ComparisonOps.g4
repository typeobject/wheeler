// Defines comparison operators
lexer grammar ComparisonOps;

// Basic comparisons
EQ          : '==';              // Equal to
NEQ         : '!=';              // Not equal to
LT          : '<';               // Less than
GT          : '>';               // Greater than
LEQ         : '<=';              // Less than or equal to
GEQ         : '>=';              // Greater than or equal to

// Type comparisons
INSTANCEOF  : 'instanceof';       // Type testing
IS          : 'is';              // Pattern matching
AS          : 'as';              // Type casting