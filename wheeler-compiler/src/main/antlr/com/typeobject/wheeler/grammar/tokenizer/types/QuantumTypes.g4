// Defines quantum-specific types
lexer grammar QuantumTypes;

// Basic quantum types
QUBIT       : 'qubit';           // Single qubit
QUREG       : 'qureg';           // Quantum register
STATE       : 'state';           // Quantum state

// Quantum circuits
CIRCUIT     : 'circuit';         // Quantum circuit
GATE        : 'gate';            // Quantum gate
ORACLE      : 'oracle';          // Quantum oracle

// Measurement types
MEASUREMENT : 'measurement';      // Measurement result
BASIS       : 'basis';           // Measurement basis

// Complex numbers
COMPLEX     : 'complex';         // Complex number type
AMPLITUDE   : 'amplitude';       // Quantum amplitude