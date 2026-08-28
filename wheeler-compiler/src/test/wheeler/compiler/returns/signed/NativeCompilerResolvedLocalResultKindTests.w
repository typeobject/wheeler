//! Checks resolved signed-local result membership through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_result_kinds;

import wheeler.compiler.resolved_local_result_kinds;

classical class NativeCompilerResolvedLocalResultKindTests {
  entry void main() {
    assert(true);
  }

  test void checksSignedReturnMembership() {
    boolean present = resolvedSignedLocalReturn(14591);
    assert(present);
  }
}
