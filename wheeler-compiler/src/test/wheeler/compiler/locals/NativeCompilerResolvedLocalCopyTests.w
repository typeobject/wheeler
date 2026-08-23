//! Checks physical resolved local-copy queries through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_copies;

import wheeler.compiler.resolved_local_copy_kinds;

classical class NativeCompilerResolvedLocalCopyTests {
  entry void main() {
    assert(true);
  }

  test void checksResolvedLongAssertionMembership() {
    boolean present = resolvedLocalLongAssertion(2303);
    assert(present);
  }

  test void checksResolvedLongCopyMembership() {
    boolean present = resolvedLocalLongCopy(2559);
    assert(present);
  }

  test void checksResolvedBooleanCopyMembership() {
    boolean present = resolvedLocalBooleanCopy(4351);
    assert(present);
  }

  test void checksResolvedBooleanNegationMembership() {
    boolean present = resolvedLocalBooleanNot(4607);
    assert(present);
  }
}
