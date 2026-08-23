//! Checks physical resolved early-comparison returns through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_early_comparisons;

import wheeler.compiler.resolved_early_comparison_kinds;

classical class NativeCompilerResolvedEarlyComparisonTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalEqualityLocalReturn() {
    boolean present = resolvedEarlyEqualityReturn(29183);
    assert(present);
  }

  test void classifiesFinalLessThanAdditionReturn() {
    boolean present = resolvedEarlyLessReturn(32255);
    assert(present);
  }
}
