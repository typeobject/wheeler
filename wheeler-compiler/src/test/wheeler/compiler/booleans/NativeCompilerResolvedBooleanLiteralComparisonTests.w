//! Checks physical resolved Boolean-literal comparisons through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_boolean_literal_comparisons;

import wheeler.compiler.resolved_boolean_literal_comparisons;

classical class NativeCompilerResolvedBooleanLiteralComparisonTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalBooleanLiteralEquality() {
    boolean equality = resolvedBooleanLiteralEquality(25343);
    assert(equality);
  }

  test void classifiesFinalBooleanLiteralInequality() {
    boolean inequality = resolvedBooleanLiteralInequality(25599);
    assert(inequality);
  }

  test void classifiesFinalBooleanLiteralComparison() {
    boolean comparison = resolvedBooleanLiteralComparison(25599);
    assert(comparison);
  }

  test void decodesFinalBooleanLiteralComparisonSource() {
    long source = resolvedBooleanLiteralComparisonSource(25599);
    assert(source == 255);
  }
}
