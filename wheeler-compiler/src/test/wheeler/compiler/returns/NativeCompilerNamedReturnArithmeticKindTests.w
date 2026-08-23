//! Checks physical unresolved arithmetic return classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_named_return_arithmetic_kinds;

import wheeler.compiler.named_return_arithmetic_kinds;

classical class NativeCompilerNamedReturnArithmeticKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalLocalBinaryReturn() {
    boolean present = returnLocalBinaryStatement(860);
    assert(present);
  }

  test void classifiesFinalLocalPairReturn() {
    boolean present = returnLocalPairStatement(861);
    assert(present);
  }
}
