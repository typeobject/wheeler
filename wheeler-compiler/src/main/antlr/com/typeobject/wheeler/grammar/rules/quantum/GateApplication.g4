// Defines rules for quantum gate applications
parser grammar GateApplication;

options { tokenVocab=WheelerLexer; }

// Quantum gate application
// Examples:
// - H(q);           // Hadamard gate
// - CNOT(control, target);
// - PHASE(q, π/2);
gateApplication
    : standardGate               // Built-in gates
    | customGate                 // User-defined gates
    | controlledGate             // Controlled operations
    ;

// Standard quantum gates
standardGate
    : HADAMARD qubitOperand SEMI                    // H gate
    | (PAULIX | PAULIY | PAULIZ) qubitOperand SEMI  // Pauli gates
    | CNOT qubitOperand COMMA qubitOperand SEMI     // CNOT gate
    | PHASE qubitOperand COMMA expression SEMI      // Phase gate
    | ROTATE qubitOperand COMMA expression SEMI     // Rotation gate
    ;

// Custom gate application
customGate
    : IDENTIFIER                // Gate name
      LPAREN
        qubitOperandList        // Qubit operands
        (COMMA expression)*     // Classical parameters
      RPAREN
      SEMI
    ;

// Controlled gate wrapper
controlledGate
    : CONTROLLED
      gateApplication
      WITH
      qubitOperand              // Control qubit
    ;