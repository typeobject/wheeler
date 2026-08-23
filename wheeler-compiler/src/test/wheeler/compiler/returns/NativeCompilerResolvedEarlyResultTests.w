//! Checks physical resolved early-result classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_early_results;

import wheeler.compiler.resolved_early_result_kinds;

classical class NativeCompilerResolvedEarlyResultTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalHelperForwardingReturn() {
    boolean present = resolvedEarlyHelperForwardingReturn(28671);
    assert(present);
  }

  test void classifiesFinalHelperReturn() {
    boolean present = resolvedEarlyHelperReturn(28671);
    assert(present);
  }

  test void classifiesFinalSignedReturn() {
    boolean present = resolvedEarlySignedReturn(32255);
    assert(present);
  }

  test void classifiesFinalLocalReturn() {
    boolean present = resolvedEarlyLocalReturn(29439);
    assert(present);
  }

  test void classifiesFinalComputedReturn() {
    boolean present = resolvedEarlyComputedReturn(32255);
    assert(present);
  }

  test void classifiesFinalAdditionReturn() {
    boolean present = resolvedEarlyAdditionReturn(32255);
    assert(present);
  }

  test void classifiesFinalRemainderReturn() {
    boolean present = resolvedEarlyRemainderReturn(28415);
    assert(present);
  }

  test void classifiesFinalDivisionReturn() {
    boolean present = resolvedEarlyDivisionReturn(28927);
    assert(present);
  }
}
