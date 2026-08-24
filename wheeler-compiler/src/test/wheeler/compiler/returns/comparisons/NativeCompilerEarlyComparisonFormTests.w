//! Checks the physical combined early-comparison classifier through native package tests.

module wheeler.compiler.tests.native_compiler_early_comparison_forms;

import wheeler.compiler.early_comparison_forms;

classical class NativeCompilerEarlyComparisonFormTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFirstResolvedEqualityForm() {
    boolean present = resolvedEarlyComparisonReturn(25856);
    assert(present);
  }

  test void classifiesFinalResolvedOrderingForm() {
    boolean present = resolvedEarlyComparisonReturn(32255);
    assert(present);
  }
}
