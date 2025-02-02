// Defines boolean logic operators
lexer grammar LogicalOps;

// Boolean operations
AND         : '&&';              // Logical AND
OR          : '||';              // Logical OR
NOT         : '!';               // Logical NOT

// Implications (used in proofs)
IMPLIES     : '=>';              // Logical implication
IFF         : '<=>';             // If and only if