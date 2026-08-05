//! Decodes resolved signed-local comparisons with literals.

module wheeler.compiler.resolved_local_literal_comparison_sources;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalLiteralComparisonSources {
  /// Returns the source local carried by a literal comparison.
  public long resolvedLocalLiteralComparisonSource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_LT_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_NE_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_LT_LITERAL_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_NE_LITERAL_BASE;
  }
}
