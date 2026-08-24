//! Checks physical unresolved early-return result classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_early_return_result_kinds;

import wheeler.compiler.early_return_result_kinds;

classical class NativeCompilerEarlyReturnResultKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalSignedHelperGuardResult() {
    boolean signed = helperGuardResultSigned(885);
    assert(signed);
  }

  test void classifiesFinalSignedComparisonGuardResult() {
    boolean signed = comparisonGuardResultSigned(934);
    assert(signed);
  }

  test void classifiesFinalComputedComparisonGuardResult() {
    boolean computed = comparisonGuardResultComputed(934);
    assert(computed);
  }

  test void classifiesComparisonGuardAdditionResult() {
    boolean addition = comparisonGuardResultAddition(934);
    assert(addition);
  }

  test void classifiesComparisonGuardRemainderResult() {
    boolean remainder = comparisonGuardResultRemainder(891);
    assert(remainder);
  }

  test void classifiesComparisonGuardDivisionResult() {
    boolean division = comparisonGuardResultDivision(912);
    assert(division);
  }
}
