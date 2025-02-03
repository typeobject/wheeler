// Defines rules for quantum control flow
parser grammar RulesQuantumQuantumControl;

options { tokenVocab=WheelerLexer; }

// Quantum control statements
quantumControlStatement
    : quantumIf                // Quantum conditional
    | quantumWhile             // Quantum loop
    | quantumUntil             // Quantum until loop
    ;

// Quantum if statement
// Example: qif (q) { X(target); }
quantumIf
    : QIF
      LPAREN qubitCondition RPAREN
      quantumBlock
      (ELSE quantumBlock)?
    ;

// Quantum while loop
// Example: qwhile (q) { ... } until (condition)
quantumWhile
    : QWHILE
      LPAREN qubitCondition RPAREN
      quantumBlock
      UNTIL
      LPAREN expression RPAREN
    ;

// Quantum block
quantumBlock
    : LBRACE
        quantumStatement*
      RBRACE
    ;

// Qubit condition (for control flow)
qubitCondition
    : qubitOperand            // Single qubit
    | qubitExpression         // Quantum expression
    ;