// Defines rules for primary expressions (basic building blocks)
parser grammar RulesExpressionsPrimaryExpr;

options { tokenVocab=WheelerLexer; }

// Primary expressions (atoms)
primary
    : LPAREN expression RPAREN         // Parenthesized expression
    | THIS                            // This reference
    | SUPER                           // Super reference
    | literal                         // Literal values
    | IDENTIFIER                      // Variable references
    | typeTypeOrVoid DOT CLASS        // Class literals
    | QUANTUM DOT STATE               // Quantum state
    | nonWildcardTypeArguments        // Generic type arguments
      (explicitGenericInvocationSuffix | THIS arguments)
    ;

// Literal values
literal
    : integerLiteral                  // Integer numbers
    | floatingPointLiteral            // Floating point numbers
    | booleanLiteral                  // true/false
    | characterLiteral                // Character literals
    | stringLiteral                   // String literals
    | nullLiteral                     // null
    | quantumLiteral                  // Quantum states
    ;

// Quantum state literals
quantumLiteral
    : QUBIT_KET                      // |0⟩, |1⟩
    | STATE_LITERAL                   // Complex state
    | MATRIX_LITERAL                  // Matrix representation
    ;
