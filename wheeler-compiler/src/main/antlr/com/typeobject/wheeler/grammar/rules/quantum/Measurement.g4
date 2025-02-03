// Defines rules for quantum measurements
parser grammar Measurement;

options { tokenVocab=WheelerLexer; }

// Measurement operations
// Examples:
// - measure q -> result;
// - measure register in basis;
measurementStatement
    : MEASURE qubitOperand
      (ARROW IDENTIFIER)?        // Optional classical result
      SEMI
    | MEASURE qubitOperand
      IN
      basisSpecification         // Measurement basis
      SEMI
    ;

// Basis specification
basisSpecification
    : standardBasis             // Computational basis
    | customBasis               // User-defined basis
    ;

// Standard measurement bases
standardBasis
    : COMPUTATIONAL            // |0⟩/|1⟩ basis
    | HADAMARD                 // |+⟩/|-⟩ basis
    ;