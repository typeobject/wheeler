//! Checks physical unresolved direct-comparison classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_named_comparison_kinds;

import wheeler.compiler.named_comparison_kinds;

classical class NativeCompilerNamedComparisonKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalDirectComparisonReturn() {
    boolean comparison = returnComparisonStatement(877);
    assert(comparison);
  }

  test void classifiesFinalDirectInequalityReturn() {
    boolean inequality = returnInequalityStatement(875);
    assert(inequality);
  }

  test void classifiesFinalDirectSignedComparisonReturn() {
    boolean signed = returnComparisonSigned(877);
    assert(signed);
  }
}
