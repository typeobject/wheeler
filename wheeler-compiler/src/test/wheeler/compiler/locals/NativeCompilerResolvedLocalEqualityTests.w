//! Checks physical resolved local-equality queries through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_equality;

import wheeler.compiler.resolved_local_equality_kinds;

classical class NativeCompilerResolvedLocalEqualityTests {
  entry void main() {
    assert(true);
  }

  test void checksResolvedEqualityMembership() {
    boolean present = resolvedLocalEquality(5119);
    assert(present);
  }

  test void checksResolvedSignedEqualityMembership() {
    boolean present = resolvedLocalEqualitySigned(4864);
    assert(present);
  }

  test void checksResolvedBooleanEqualitySource() {
    long source = resolvedLocalEqualitySource(4608);
    assert(source == 0);
  }
}
