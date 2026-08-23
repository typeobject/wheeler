//! Checks physical resolved local-loop classification through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_loop_kinds;

import wheeler.compiler.resolved_local_loop_kinds;

classical class NativeCompilerResolvedLocalLoopKindTests {
  entry void main() {
    assert(true);
  }

  test void checksFinalResolvedLocalLoop() {
    boolean present = resolvedLocalWhile(24831);
    assert(present);
  }
}
