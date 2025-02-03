// Defines rules for proof structure and organization
parser grammar RulesProofsProofStructure;

options { tokenVocab=WheelerLexer; }

// Proof class declaration
// Example:
// proof class VectorSpaceProofs for VectorSpace { ... }
proofClassDeclaration
    : annotation*                         // Optional annotations
      PROOF CLASS                         // Proof class keywords
      IDENTIFIER                          // Class name
      FOR qualifiedName                   // Target type
      proofClassBody                      // Proof implementations
    ;

// Proof class body
proofClassBody
    : LBRACE
        (theoremDeclaration              // Theorems
        | lemmaDeclaration               // Helper lemmas
        | proofHelperMethod)*            // Helper methods
      RBRACE
    ;

// Lemma declaration (helper theorem)
lemmaDeclaration
    : annotation*                        // Optional annotations
      computationType?                   // Computation type
      LEMMA                              // Lemma keyword
      IDENTIFIER                         // Lemma name
      lemmaParameters?                   // Parameters
      theoremConditions?                 // Conditions
      proofBody                          // Implementation
    ;

// Helper method for proofs
proofHelperMethod
    : annotation*                       // Optional annotations
      (PURE | CLASSICAL | QUANTUM)?     // Method type
      typeTypeOrVoid                    // Return type
      IDENTIFIER                        // Method name
      formalParameters                  // Parameters
      methodBody                        // Implementation
    ;