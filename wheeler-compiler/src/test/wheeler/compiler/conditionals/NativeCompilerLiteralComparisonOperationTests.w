//! Checks physical literal-comparison operation classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_literal_comparison_operations;

import wheeler.compiler.literal_comparison_operations;

classical class NativeCompilerLiteralComparisonOperationTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalLiteralComparisonLessThan() {
    boolean lessThan = literalComparisonConditionalLessThan(14335);
    assert(lessThan);
  }

  test void classifiesFinalLiteralComparisonSubtract() {
    boolean subtract = literalComparisonConditionalSubtract(13823);
    assert(subtract);
  }

  test void classifiesFinalLiteralComparisonXor() {
    boolean xor = literalComparisonConditionalXor(14079);
    assert(xor);
  }

  test void classifiesFinalLiteralComparisonAssignment() {
    boolean assignment = literalComparisonConditionalAssignment(14335);
    assert(assignment);
  }
}
