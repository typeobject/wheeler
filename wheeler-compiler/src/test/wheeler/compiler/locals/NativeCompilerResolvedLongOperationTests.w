//! Checks physical resolved signed-local operations through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_long_operations;

import wheeler.compiler.resolved_long_operations;

classical class NativeCompilerResolvedLongOperationTests {
  entry void main() {
    assert(true);
  }

  test void checksResolvedLongBinaryMembership() {
    boolean present = resolvedLocalLongBinary(15103);
    assert(present);
  }

  test void checksResolvedLongBinarySource() {
    long source = resolvedLocalLongBinarySource(14848);
    assert(source == 0);
  }

  test void checksResolvedLongPairMembership() {
    boolean present = resolvedLocalLongPair(15359);
    assert(present);
  }

  test void checksResolvedLongPairSource() {
    long source = resolvedLocalLongPairSource(15104);
    assert(source == 0);
  }
}
