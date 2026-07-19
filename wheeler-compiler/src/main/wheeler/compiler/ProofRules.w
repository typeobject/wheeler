//! Defines canonical proof-rule codes for Wheeler-written bytecode tools.
module wheeler.compiler.proof_rules;

classical class ProofRules {
  /// Names the compile-time `PROOF_GENERATED_INVERSE` value owned by this module.
  public const long PROOF_GENERATED_INVERSE = 1;
  /// Names the compile-time `PROOF_STATIC_STEP_BOUND` value owned by this module.
  public const long PROOF_STATIC_STEP_BOUND = 4;
}
