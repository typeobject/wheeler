//! Checks physical resolved early-return source decoders through native package tests.

module wheeler.compiler.tests.native_compiler_early_return_sources;

import wheeler.compiler.early_return_sources;

classical class NativeCompilerEarlyReturnSourceTests {
  entry void main() {
    assert(true);
  }

  test void decodesFinalHelperForwardingSource() {
    long source = earlyHelperReturnSource(28671);
    assert(source == 255);
  }

  test void decodesFinalComparisonAdditionSource() {
    long source = earlyComparisonReturnSource(32255);
    assert(source == 255);
  }
}
