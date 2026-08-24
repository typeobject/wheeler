//! Checks physical two-argument call classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_two_argument_call_kinds;

import wheeler.compiler.two_argument_call_kinds;

classical class NativeCompilerTwoArgumentCallKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalTwoArgumentCall() {
    boolean call = twoArgumentCallStatement(871);
    assert(call);
  }

  test void classifiesFinalSignedResultTwoArgumentCall() {
    boolean call = twoArgumentSignedResultCall(844);
    assert(call);
  }

  test void classifiesFinalBooleanTwoArgumentCall() {
    boolean call = twoArgumentBooleanCall(852);
    assert(call);
  }

  test void classifiesFinalSignedBooleanTwoArgumentCall() {
    boolean call = twoArgumentBooleanSignedCall(871);
    assert(call);
  }
}
