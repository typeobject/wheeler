//! Checks physical resolved local-inequality queries through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_inequality;

import wheeler.compiler.resolved_local_inequality_kinds;

classical class NativeCompilerResolvedLocalInequalityTests {
  entry void main() {
    assert(true);
  }

  test void checksResolvedInequalityMembership() {
    boolean present = resolvedLocalInequality(15871);
    assert(present);
  }

  test void checksResolvedSignedInequalityMembership() {
    boolean present = resolvedLocalInequalitySigned(15616);
    assert(present);
  }

  test void checksResolvedBooleanInequalitySource() {
    long source = resolvedLocalInequalitySource(15360);
    assert(source == 0);
  }
}
