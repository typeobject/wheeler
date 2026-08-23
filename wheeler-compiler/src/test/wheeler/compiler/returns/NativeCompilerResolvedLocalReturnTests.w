//! Checks physical resolved local-return queries through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_returns;

import wheeler.compiler.resolved_local_returns;

classical class NativeCompilerResolvedLocalReturnTests {
  entry void main() {
    assert(true);
  }

  test void checksResolvedReturnMembership() {
    boolean present = resolvedLocalReturn(14847);
    assert(present);
  }

  test void checksSignedReturnMembership() {
    boolean present = resolvedSignedLocalReturn(14591);
    assert(present);
  }

  test void checksBooleanReturnSource() {
    long source = resolvedLocalReturnSource(14592);
    assert(source == 0);
  }
}
