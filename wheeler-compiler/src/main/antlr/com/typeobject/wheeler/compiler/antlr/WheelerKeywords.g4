lexer grammar WheelerKeywords;

@header {
package com.typeobject.wheeler.compiler.antlr;
}

// Program structure
PACKAGE: 'package';
IMPORT: 'import';
MODULE: 'module';
EXPORTS: 'exports';
REQUIRES: 'requires';
USES: 'uses';
TO: 'to';

// Class-related
CLASS: 'class';
INTERFACE: 'interface';
EXTENDS: 'extends';
IMPLEMENTS: 'implements';
NEW: 'new';
THIS: 'this';
SUPER: 'super';

// Modifiers
PUBLIC: 'public';
PRIVATE: 'private';
PROTECTED: 'protected';
STATIC: 'static';
FINAL: 'final';
ABSTRACT: 'abstract';
SYNCHRONIZED: 'synchronized';
DEFAULT: 'default';

// Computation types
REV: 'rev';
PURE: 'pure';
CLASSICAL: 'classical';
QUANTUM: 'quantum';
HYBRID: 'hybrid';

// Variable declaration
VAR: 'var';
LET: 'let';
HIST: 'hist';

// Quantum specific
QUBIT: 'qubit';
QUREG: 'qureg';
STATE: 'state';
ORACLE: 'oracle';
MEASURE: 'measure';
PREPARE: 'prepare';
SUPERPOSITION: 'superposition';

// Control flow
IF: 'if';
ELSE: 'else';
SWITCH: 'switch';
CASE: 'case';
FOR: 'for';
WHILE: 'while';
DO: 'do';
BREAK: 'break';
CONTINUE: 'continue';
RETURN: 'return';
MATCH: 'match';

// Quantum control
QIF: 'qif';
QWHILE: 'qwhile';
UNTIL: 'until';

// Error handling
TRY: 'try';
CATCH: 'catch';
FINALLY: 'finally';
THROW: 'throw';
THROWS: 'throws';

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

// Additional keywords needed
ENUM: 'enum';