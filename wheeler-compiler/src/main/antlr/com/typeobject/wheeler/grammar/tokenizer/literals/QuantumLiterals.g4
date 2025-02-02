// Defines quantum state literals
lexer grammar QuantumLiterals;

// Quantum state literals
QUBIT_KET
    : '|' [01] '⟩'                 // Basic qubit states
    | '|+⟩'                        // Plus state
    | '|-⟩'                        // Minus state
    ;

QUBIT_BRA
    : '⟨' [01] '|'                 // Dual states
    | '⟨+|'
    | '⟨-|'
    ;

STATE_LITERAL
    : StateCoefficient? QUBIT_KET  // State with optional coefficient
    ;

// Fragment rules for quantum components
fragment StateCoefficient
    : ('√'? [0-9]+ '/' [0-9]+)    // Rational coefficients
    | ComplexNumber                // Complex coefficients
    ;