// Defines rules for quantum circuit declarations and structure
parser grammar RulesQuantumCircuitDecl;

options { tokenVocab=WheelerLexer; }

// Quantum circuit declaration
// Examples:
// - quantum circuit Bell(qubit a, qubit b) { H(a); CNOT(a, b); }
// - quantum circuit QFT(qureg q) { ... }
circuitDeclaration
    : annotation*                    // Optional annotations
      QUANTUM CIRCUIT                // Circuit declaration
      IDENTIFIER                     // Circuit name
      formalParameters               // Input parameters
      circuitBody                    // Circuit implementation
    ;

// Circuit body containing quantum operations
circuitBody
    : LBRACE
        quantumStatement*           // Sequence of quantum operations
      RBRACE
    ;

// Circuit parameters
circuitFormalParameters
    : LPAREN
        circuitParameter?
        (COMMA circuitParameter)*
      RPAREN
    ;

// Individual circuit parameter
circuitParameter
    : QUBIT IDENTIFIER            // Single qubit parameter
    | QUREG IDENTIFIER            // Quantum register parameter
    ;