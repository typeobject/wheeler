//! Combines resolved equality and ordering guard families.

module wheeler.compiler.early_comparison_forms;

import wheeler.compiler.resolved_early_comparison_kinds;

classical class EarlyComparisonForms {
  /// Checks whether an opcode guards one resolved scalar comparison.
  public boolean resolvedEarlyComparisonReturn(long opcode) {
    if (resolvedEarlyEqualityReturn(opcode)) {
      return true;
    }

    return resolvedEarlyLessReturn(opcode);
  }
}
