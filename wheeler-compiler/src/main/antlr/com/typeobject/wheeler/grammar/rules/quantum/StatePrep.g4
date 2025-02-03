// Defines rules for quantum state preparation
parser grammar StatePrep;

options { tokenVocab=WheelerLexer; }

// State preparation
// Examples:
// - prepare q |0⟩;
// - prepare reg |+⟩⊗n;
// - prepare q (α|0⟩ + β|1⟩);
statePreparation
    : PREPARE qubitOperand
      stateSpecification
      SEMI
    ;

// State specification
stateSpecification
    : QUBIT_KET               // Basic state (|0⟩, |1⟩)
    | STATE_LITERAL           // Complex state
    | tensorProduct           // Tensor product of states
    | superposition           // Superposition state
    ;

// Tensor product of states
tensorProduct
    : stateSpecification
      TENSOR
      stateSpecification
    ;

// Superposition state
superposition
    : LPAREN
      stateSum
      RPAREN
    ;
