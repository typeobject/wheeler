//! Checks physical one-argument call classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_one_argument_calls;

import wheeler.compiler.one_argument_calls;

classical class NativeCompilerOneArgumentCallTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalOneArgumentCall() {
    boolean call = oneArgumentCallStatement(867);
    assert(call);
  }

  test void classifiesFinalNamedOneArgumentCall() {
    boolean named = oneArgumentCallNamed(867);
    assert(named);
  }

  test void classifiesFinalBooleanOneArgumentCall() {
    boolean call = oneArgumentBooleanCall(848);
    assert(call);
  }

  test void classifiesFinalSignedBooleanOneArgumentCall() {
    boolean call = oneArgumentBooleanSignedCall(867);
    assert(call);
  }
}
