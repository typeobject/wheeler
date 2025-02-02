// Defines formal verification and proof system keywords
lexer grammar ProofKeywords;

// Proof structure
THEOREM     : 'theorem';         // Theorem declaration
LEMMA       : 'lemma';           // Supporting lemma
PROOF       : 'proof';           // Proof block
VERIFY      : 'verify';          // Verification step
BECAUSE     : 'because';         // Justification
QED         : 'qed';             // Proof completion

// Proof conditions
GIVEN       : 'given';           // Assumptions
SHOWS       : 'shows';           // Conclusion

// Logical quantifiers (used in proofs)
FORALL      : 'forall';          // Universal quantifier
EXISTS      : 'exists';          // Existential quantifier
IMPLIES     : 'implies';         // Logical implication