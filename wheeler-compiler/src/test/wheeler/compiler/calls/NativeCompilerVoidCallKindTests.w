//! Checks all physical resolved void-call shape queries through native package tests.

module wheeler.compiler.tests.native_compiler_void_call_kinds;

import wheeler.compiler.void_call_kinds;

classical class NativeCompilerVoidCallKindTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentResolvedMembership() {
    boolean present = voidCallStatement(31744);
    assert(present);
  }

  test void checksSevenArgumentResolvedArity() {
    long arity = voidCallArity(31744);
    assert(arity == 7);
  }

  test void checksThreeArgumentResolvedSource() {
    long source = voidCallThirdSource(131124);
    assert(source == 42);
  }
}
