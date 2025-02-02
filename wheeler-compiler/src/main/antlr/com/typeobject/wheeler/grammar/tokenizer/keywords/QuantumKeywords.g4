// Defines quantum computing specific keywords
lexer grammar QuantumKeywords;

// Quantum types
QUBIT       : 'qubit';           // Single qubit
QUREG       : 'qureg';           // Quantum register
STATE       : 'state';           // Quantum state
ORACLE      : 'oracle';          // Quantum oracle

// Quantum operations
MEASURE     : 'measure';         // State measurement
PREPARE     : 'prepare';         // State preparation
SUPERPOSITION : 'superposition'; // Superposition creation

// Quantum control flow
QIF         : 'qif';             // Quantum conditional
QWHILE      : 'qwhile';          // Quantum while loop
UNTIL       : 'until';           // Quantum loop condition

// Quantum computation mode
QUANTUM     : 'quantum';         // Quantum block marker

// Standard gates
HADAMARD    : 'H';               // Hadamard gate
PAULIX      : 'X';               // Pauli-X gate
PAULIY      : 'Y';               // Pauli-Y gate
PAULIZ      : 'Z';               // Pauli-Z gate
CNOT        : 'CNOT';            // Controlled-NOT gate
TOFFOLI     : 'TOFFOLI';         // Toffoli gate
PHASE       : 'PHASE';           // Phase gate
ROTATE      : 'ROTATE';          // Rotation gate