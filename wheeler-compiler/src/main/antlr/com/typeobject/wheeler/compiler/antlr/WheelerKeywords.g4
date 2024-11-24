lexer grammar WheelerKeywords;

@header {
package com.typeobject.wheeler.compiler.antlr;
}

// Program structure
PACKAGE: 'package';
IMPORT: 'import';
MODULE: 'module';

// Class-related
CLASS: 'class';
INTERFACE: 'interface';
EXTENDS: 'extends';
IMPLEMENTS: 'implements';
NEW: 'new';

// Modifiers
PUBLIC: 'public';
PRIVATE: 'private';
PROTECTED: 'protected';
STATIC: 'static';
FINAL: 'final';
ABSTRACT: 'abstract';
SYNCHRONIZED: 'synchronized';

// Computation types
REV: 'rev';              // Reversible
PURE: 'pure';            // Pure function
CLASSICAL: 'classical';   // Classical computation
QUANTUM: 'quantum';      // Quantum computation
HYBRID: 'hybrid';        // Hybrid computation

// Variable declaration
VAR: 'var';              // Mutable variable
LET: 'let';              // Immutable variable
HIST: 'hist';            // Historical value

// Quantum specific
QUBIT: 'qubit';          // Single qubit
QUREG: 'qureg';          // Quantum register
STATE: 'state';          // Quantum state
ORACLE: 'oracle';        // Quantum oracle
MEASURE: 'measure';      // Measurement
PREPARE: 'prepare';      // State preparation

// Control flow
IF: 'if';
ELSE: 'else';
SWITCH: 'switch';
CASE: 'case';
DEFAULT: 'default';
FOR: 'for';
WHILE: 'while';
DO: 'do';
BREAK: 'break';
CONTINUE: 'continue';
RETURN: 'return';
MATCH: 'match';

// Quantum control
QIF: 'qif';              // Quantum conditional
QWHILE: 'qwhile';        // Quantum loop
UNTIL: 'until';          // Quantum termination

// Error handling
TRY: 'try';
CATCH: 'catch';
FINALLY: 'finally';
THROW: 'throw';

// Memory management
UNCOMPUTE: 'uncompute';
CLEAN: 'clean';

// Transaction control
TRANSACTION: 'transaction';
COMMIT: 'commit';
ROLLBACK: 'rollback';

// Quantum gates
HADAMARD: 'H';
PAULIX: 'X';
PAULIY: 'Y';
PAULIZ: 'Z';
CNOT: 'CNOT';
TOFFOLI: 'TOFFOLI';
PHASE: 'PHASE';
ROTATE: 'ROTATE';