//! Checks physical resolved literal-comparison classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_literal_comparison_kinds;

import wheeler.compiler.resolved_literal_comparison_kinds;

classical class NativeCompilerResolvedLiteralComparisonKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalResolvedLiteralComparison() {
    boolean present = resolvedLiteralComparisonConditional(14335);
    assert(present);
  }

  test void decodesFinalResolvedLiteralComparisonSource() {
    long source = resolvedLiteralComparisonConditionalSource(14335);
    assert(source == 255);
  }
}
