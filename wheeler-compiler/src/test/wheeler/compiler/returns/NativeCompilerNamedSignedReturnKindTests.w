//! Checks physical unresolved signed return classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_named_signed_return_kinds;

import wheeler.compiler.named_signed_return_kinds;

classical class NativeCompilerNamedSignedReturnKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalSignedEqualityReturn() {
    boolean present = returnSignedEqualityStatement(873);
    assert(present);
  }

  test void classifiesFinalSignedInequalityReturn() {
    boolean present = returnSignedInequalityStatement(875);
    assert(present);
  }

  test void classifiesFinalSignedLessThanReturn() {
    boolean present = returnSignedLessThanStatement(877);
    assert(present);
  }
}
