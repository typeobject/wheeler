// Defines quantum-specific operators
lexer grammar QuantumOps;

// Quantum operations
TENSOR      : '⊗';               // Tensor product
CONJUGATE   : '†';               // Hermitian conjugate
MEASURE_ARROW : '=>';            // Measurement result assignment

// Phase operations
PHASE_EXP   : 'e^{i';           // Complex exponential

// Quantum circuit symbols
WIRE_CROSS  : '⨯';              // Circuit wire crossing
CONTROL_DOT : '●';              // Control point
TARGET_CROSS: '⊕';              // Target point (e.g., for CNOT)ential