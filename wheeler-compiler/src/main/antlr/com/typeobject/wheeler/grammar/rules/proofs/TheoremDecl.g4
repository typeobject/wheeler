// Defines rules for theorem declarations and their properties
parser grammar TheoremDecl;

options { tokenVocab=WheelerLexer; }

// Theorem declaration
// Examples:
// - theorem Associativity { ... }
// - quantum theorem StatePreservation given: isUnitary(U) shows: ... { ... }
theoremDeclaration
    : annotation*                          // Optional annotations
      computationType?                     // classical/quantum/hybrid
      THEOREM                              // Theorem keyword
      IDENTIFIER                           // Theorem name
      typeParameters?                      // Optional generic parameters
      theoremParameters?                   // Theorem parameters
      theoremConditions?                   // Given/shows conditions
      theoremBody                          // Theorem implementation
    ;

// Theorem parameters (arguments)
theoremParameters
    : LPAREN
        parameterDeclaration
        (COMMA parameterDeclaration)*
      RPAREN
    ;

// Theorem conditions
theoremConditions
    : givenClause?                         // Preconditions
      showsClause                          // What to prove
    ;

// Given clause (preconditions)
givenClause
    : GIVEN COLON
      expression
      (COMMA expression)*
    ;

// Shows clause (theorem statement)
showsClause
    : SHOWS COLON expression
    ;
