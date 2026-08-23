//! Checks physical resolved local less-than classification through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_less_than;

import wheeler.compiler.resolved_local_less_than_kinds;

classical class NativeCompilerResolvedLocalLessThanTests {
  entry void main() {
    assert(true);
  }

  test void checksFinalResolvedLocalLessThan() {
    boolean present = resolvedLocalLongLessThan(5375);
    assert(present);
  }
}
