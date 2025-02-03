// Defines rules for verification statements within proofs
parser grammar VerificationStmt;

options { tokenVocab=WheelerLexer; }

// Verification statement
// Examples:
// - verify x > 0;
// - verify isUnitary(U) because UnitaryPreserved;
verifyStatement
    : VERIFY
      expression                         // Property to verify
      (justification)?                   // Optional justification
      SEMI
    ;

// Justification for verification
justification
    : BECAUSE
      (
        theoremReference               // Reference to theorem
      | expression                     // Justifying expression
      )
    ;

// Reference to another theorem
theoremReference
    : qualifiedName                     // Theorem name
    | IDENTIFIER
      argumentList?                     // Theorem with args
    ;

// Assertion in proof
assertStatement
    : ASSERT
      expression
      (COLON expression)?              // Optional message
      SEMI
    ;