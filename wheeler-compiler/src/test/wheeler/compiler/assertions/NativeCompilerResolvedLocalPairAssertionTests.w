//! Checks physical resolved two-local assertions through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_pair_assertions;

import wheeler.compiler.resolved_local_pair_assertions;

classical class NativeCompilerResolvedLocalPairAssertionTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalBooleanPairAssertion() {
    boolean present = resolvedLocalPairAssertion(8191);
    assert(present);
  }

  test void classifiesFinalSignedPairAssertion() {
    boolean signed = resolvedLocalPairAssertionSigned(7935);
    assert(signed);
  }

  test void decodesFinalSignedPairAssertionSource() {
    long source = resolvedLocalPairAssertionSource(7935);
    assert(source == 255);
  }

  test void decodesFinalBooleanPairAssertionSource() {
    long source = resolvedLocalPairAssertionSource(8191);
    assert(source == 255);
  }
}
