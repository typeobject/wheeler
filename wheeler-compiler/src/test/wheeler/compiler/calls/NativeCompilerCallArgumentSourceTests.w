//! Checks physical two-argument call source classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_call_argument_sources;

import wheeler.compiler.call_argument_sources;

classical class NativeCompilerCallArgumentSourceTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalFirstNamedCallArgument() {
    boolean named = twoArgumentCallFirstNamed(871);
    assert(named);
  }

  test void classifiesFinalSecondNamedCallArgument() {
    boolean named = twoArgumentCallSecondNamed(871);
    assert(named);
  }
}
