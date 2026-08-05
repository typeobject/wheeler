//! Classifies scalar result forms used by bounded early returns.

module wheeler.compiler.early_return_result_kinds;

import wheeler.compiler.statement_kinds;

classical class EarlyReturnResultKinds {
  /// Checks whether one helper-call guard returns a signed result.
  public boolean helperGuardResultSigned(long sourceOpcode) {
    return sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED;
  }

  /// Checks whether one comparison guard returns a signed result.
  public boolean comparisonGuardResultSigned(long sourceOpcode) {
    if (sourceOpcode == STATEMENT_IF_SIGNED_EQ_RETURN_LONG_NAMED) {
      return true;
    }

    if (sourceOpcode == STATEMENT_IF_SIGNED_LT_RETURN_LONG_NAMED) {
      return true;
    }

    return sourceOpcode == STATEMENT_IF_SIGNED_LT_RETURN_SUB_NAMED;
  }

  /// Checks whether one comparison guard computes its result.
  public boolean comparisonGuardResultComputed(long sourceOpcode) {
    return sourceOpcode == STATEMENT_IF_SIGNED_LT_RETURN_SUB_NAMED;
  }
}
