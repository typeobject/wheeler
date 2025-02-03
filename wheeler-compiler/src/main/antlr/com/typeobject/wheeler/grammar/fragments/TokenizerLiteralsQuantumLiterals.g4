// Defines quantum state literals
lexer grammar TokenizerLiteralsQuantumLiterals;

// Basic quantum states (|0⟩, |1⟩)
QUBIT_KET
    : '|' ([01] | '+' | '-') '⟩'
    ;

// State with optional coefficient
STATE_LITERAL
    : StateCoefficient? QUBIT_KET
    ;

// Matrix representation
MATRIX_LITERAL
    : '[[' ComplexNumber (',' ComplexNumber)* ']]'
    ;

// Complex numbers for quantum states
fragment ComplexNumber
    : [0-9]+ ('.' [0-9]*)?                         // Real part
    | [0-9]+ ('.' [0-9]*)? 'i'                     // Imaginary part
    | [0-9]+ ('.' [0-9]*)? [+-] [0-9]+
      ('.' [0-9]*)? 'i'                            // Both parts
    ;

// State coefficients
fragment StateCoefficient
    : ('√'? [0-9]+ '/' [0-9]+)                     // Rational coefficient
    | ComplexNumber                                // Complex coefficient
    ;

// Bra notation
QUBIT_BRA
    : '⟨' ([01] | '+' | '-') '|'
    ;