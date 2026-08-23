//! Checks physical unresolved literal-comparison conditions through native package tests.

module wheeler.compiler.tests.native_compiler_named_literal_comparison_kinds;

import wheeler.compiler.named_literal_comparison_kinds;

classical class NativeCompilerNamedLiteralComparisonKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalLiteralComparisonConditional() {
    boolean present = namedLiteralComparisonConditional(825);
    assert(present);
  }
}
