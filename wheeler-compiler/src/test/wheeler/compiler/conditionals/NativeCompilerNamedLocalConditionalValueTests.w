//! Checks physical unresolved local-conditional values through native package tests.

module wheeler.compiler.tests.native_compiler_named_local_conditional_values;

import wheeler.compiler.named_local_conditional_values;

classical class NativeCompilerNamedLocalConditionalValueTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalNamedConditionalValue() {
    boolean present = namedLocalConditionalValue(814);
    assert(present);
  }
}
