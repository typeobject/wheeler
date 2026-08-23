//! Checks physical resolved Boolean-literal assertions through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_boolean_literal_assertions;

import wheeler.compiler.resolved_boolean_literal_assertions;

classical class NativeCompilerResolvedBooleanLiteralAssertionTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalBooleanLiteralAssertion() {
    boolean present = resolvedBooleanLiteralAssertion(25855);
    assert(present);
  }

  test void decodesFinalBooleanLiteralAssertionSource() {
    long source = resolvedBooleanLiteralAssertionSource(25855);
    assert(source == 255);
  }
}
