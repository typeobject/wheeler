// Defines quantum-specific operators
lexer grammar QuantumOps;

// Quantum operations
TENSOR      : '⊗';               // Tensor product
CONJUGATE   : '†';               // Hermitian conjugate
MEASURE_ARROW : '=>';            // Measurement result assignment

// Bra-Ket notation
KET_OPEN    : '|';               // Ket opening
KET_CLOSE   : '⟩';               // Ket closing
BRA_OPEN    : '⟨';               // Bra opening
BRA_CLOSE   : '|';               // Bra closing

// Phase operations
PHASE_EXP   : 'e^{i';            // Complex exponential