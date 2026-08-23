//! Checks physical local-literal comparison classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_literal_comparisons;

import wheeler.compiler.resolved_local_literal_comparisons;

classical class NativeCompilerResolvedLocalLiteralComparisonTests {
  entry void main() {
    assert(true);
  }

  test void classifiesEquality() {
    boolean present = resolvedLocalLiteralEquality(12031);
    assert(present);
  }

  test void classifiesInequality() {
    boolean present = resolvedLocalLiteralInequality(16127);
    assert(present);
  }

  test void classifiesLessThan() {
    boolean present = resolvedLocalLiteralLessThan(12287);
    assert(present);
  }

  test void classifiesComparison() {
    boolean present = resolvedLocalLiteralComparison(16127);
    assert(present);
  }
}
