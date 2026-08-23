//! Checks physical unresolved return-comparison operands through native package tests.

module wheeler.compiler.tests.native_compiler_named_return_comparison_operands;

import wheeler.compiler.named_return_comparison_operands;

classical class NativeCompilerNamedReturnComparisonOperandTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalLocalRightComparison() {
    boolean local = returnComparisonLocalRight(877);
    assert(local);
  }
}
