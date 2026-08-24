//! Checks physical unresolved local-update classification through native package tests.

module wheeler.compiler.tests.native_compiler_named_local_update_kinds;

import wheeler.compiler.named_local_update_kinds;

classical class NativeCompilerNamedLocalUpdateKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalNamedLocalUpdate() {
    boolean update = localUpdateSourceStatement(808);
    assert(update);
  }
}
