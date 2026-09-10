//! Defines counted classical certificate columns and their unverified argument domain.

module wheeler.compiler.closure.classical_proof_products;

import wheeler.compiler.proof_rules;

classical class ClassicalProofProducts {
  /// Bounds retained classical certificates independently of module-local source proofs.
  public const long MAX_CLASSICAL_PROOFS = 4096;
  /// Counts owner, name, rule, subject, and the two argument words.
  public const long CLASSICAL_PROOF_COLUMNS = 6;
  /// Sizes the complete counted certificate table.
  public const long CLASSICAL_PROOF_ROWS = MAX_CLASSICAL_PROOFS * CLASSICAL_PROOF_COLUMNS;
  /// Locates closure string references.
  public const long PROOF_NAME_ROW = MAX_CLASSICAL_PROOFS;
  /// Locates canonical rule codes.
  public const long PROOF_RULE_ROW = MAX_CLASSICAL_PROOFS * 2;
  /// Locates closure function subjects, never circuit subjects.
  public const long PROOF_SUBJECT_ROW = MAX_CLASSICAL_PROOFS * 3;
  /// Locates the least significant unsigned argument word.
  public const long PROOF_ARGUMENT_LOW_ROW = MAX_CLASSICAL_PROOFS * 4;
  /// Locates the most significant unsigned argument word.
  public const long PROOF_ARGUMENT_HIGH_ROW = MAX_CLASSICAL_PROOFS * 5;
  /// Sizes each serialized certificate word.
  public const long PROOF_WORD_BYTES = 4;
  /// Sizes an ID, name, rule, subject, and split argument in format 1.0.
  public const long CLASSICAL_PROOF_DESCRIPTOR_BYTES = CLASSICAL_PROOF_COLUMNS * PROOF_WORD_BYTES;

  private const long BYTE_RADIX = 256;
  private const long ARGUMENT_WORD_RADIX = BYTE_RADIX * BYTE_RADIX * BYTE_RADIX * BYTE_RADIX;
  private const long ARGUMENT_WORD_MAX = ARGUMENT_WORD_RADIX - 1;
  private const long SIGNED_HIGH_WORD_LIMIT = ARGUMENT_WORD_RADIX / 2;

  /// Checks certificate shape, not whether its claim holds for the final function body.
  /// Inverse claims carry -1; step claims carry a positive signed 64-bit bound.
  public boolean classicalProofArgumentValid(long rule, long low, long high) {
    if (low < 0) {
      return false;
    }

    if (ARGUMENT_WORD_MAX < low) {
      return false;
    }

    if (high < 0) {
      return false;
    }

    if (ARGUMENT_WORD_MAX < high) {
      return false;
    }

    if (rule == PROOF_GENERATED_INVERSE) {
      if (low != ARGUMENT_WORD_MAX) {
        return false;
      }

      return high == ARGUMENT_WORD_MAX;
    }

    if (rule == PROOF_STATIC_STEP_BOUND) {
      if (SIGNED_HIGH_WORD_LIMIT < high + 1) {
        return false;
      }

      if (low == 0) {
        return 0 < high;
      }

      return true;
    }

    return false;
  }
}
