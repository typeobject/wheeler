//! Checks physical unresolved early-return classification through native package tests.

module wheeler.compiler.tests.native_compiler_early_return_kinds;

import wheeler.compiler.early_return_kinds;

classical class NativeCompilerEarlyReturnKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalEarlyReturn() {
    boolean early = earlyReturnStatement(934);
    assert(early);
  }

  test void mapsFinalEarlyReturnLocalCount() {
    long count = sourceEarlyReturnLocalCount(934);
    assert(count == 6);
  }
}
