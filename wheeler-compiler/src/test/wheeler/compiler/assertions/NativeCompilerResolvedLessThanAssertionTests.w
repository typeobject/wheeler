//! Checks physical resolved signed less-than assertions through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_less_than_assertions;

import wheeler.compiler.resolved_less_than_assertions;

classical class NativeCompilerResolvedLessThanAssertionTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalLocalLessThanAssertion() {
    boolean present = resolvedLocalLessThanAssertion(8447);
    assert(present);
  }

  test void classifiesFinalLiteralLessThanAssertion() {
    boolean present = resolvedLiteralLessThanAssertion(25087);
    assert(present);
  }

  test void decodesFinalLiteralLessThanAssertionSource() {
    long source = resolvedLiteralLessThanAssertionSource(25087);
    assert(source == 255);
  }
}
