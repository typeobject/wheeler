//! Checks physical named conditional base mapping through native package tests.

module wheeler.compiler.tests.native_compiler_named_conditional_bases;

import wheeler.compiler.named_conditional_bases;

classical class NativeCompilerNamedConditionalBaseTests {
  entry void main() {
    assert(true);
  }

  test void mapsFinalNamedLiteralComparisonBase() {
    long base = namedLiteralComparisonConditionalBase(825);
    assert(base == 14080);
  }

  test void mapsFinalNamedLocalConditionalBase() {
    long base = namedLocalConditionalBase(814);
    assert(base == 11520);
  }
}
