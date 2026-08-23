//! Checks physical unresolved Boolean return classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_named_boolean_return_kinds;

import wheeler.compiler.named_boolean_return_kinds;

classical class NativeCompilerNamedBooleanReturnKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalBooleanEqualityReturn() {
    boolean present = returnBooleanEqualityStatement(857);
    assert(present);
  }

  test void classifiesFinalBooleanInequalityReturn() {
    boolean present = returnBooleanInequalityStatement(865);
    assert(present);
  }

  test void classifiesFinalBooleanComparisonReturn() {
    boolean present = returnBooleanComparisonStatement(865);
    assert(present);
  }
}
