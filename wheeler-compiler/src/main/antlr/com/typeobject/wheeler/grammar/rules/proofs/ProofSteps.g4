// Defines rules for individual proof steps and techniques
parser grammar ProofSteps;

options { tokenVocab=WheelerLexer; }

// Proof body containing steps
proofBody
    : LBRACE
        PROOF                          // Proof block start
        proofStatement*                // Sequence of steps
        QED                           // Proof completion
        SEMI
      RBRACE
    ;

// Individual proof statements
proofStatement
    : letDeclaration                  // Variable declaration
    | verifyStatement                 // Property verification
    | assertStatement                 // Assertion
    | quantumStatement                // Quantum operation
    | classicalStatement              // Classical computation
    | proofCase                      // Case analysis
    | inductionStep                  // Induction
    ;

// Case analysis in proof
proofCase
    : CASE expression COLON           // Case condition
      LBRACE
        proofStatement*
      RBRACE
    ;

// Induction step
inductionStep
    : INDUCTION ON expression         // Induction variable
      LBRACE
        baseCase
        inductiveCase
      RBRACE
    ;

// Base case of induction
baseCase
    : BASE CASE COLON
      proofStatement*
    ;

// Inductive case
inductiveCase
    : INDUCTIVE CASE COLON
      proofStatement*
    ;

// let declarations in proofs
letDeclaration
    : LET
      variableDeclarator
      (COMMA variableDeclarator)*
      SEMI
    ;