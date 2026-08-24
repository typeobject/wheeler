//! Checks physical resolved local-update classification and decoding through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_updates;

import wheeler.compiler.resolved_local_updates;

classical class NativeCompilerResolvedLocalUpdateTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalResolvedLocalUpdate() {
    boolean update = resolvedLocalUpdate(17663);
    assert(update);
  }

  test void classifiesFinalNamedResolvedLocalUpdate() {
    boolean named = resolvedLocalUpdateNamed(17663);
    assert(named);
  }

  test void decodesFinalResolvedLocalUpdateTarget() {
    long target = resolvedLocalUpdateTarget(17663);
    assert(target == 255);
  }
}
