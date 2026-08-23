//! Checks the physical packed void-call source decoder through native package tests.

module wheeler.compiler.tests.native_compiler_void_call_operand;

import wheeler.compiler.void_call_operands;

classical class NativeCompilerVoidCallOperandTests {
  entry void main() {
    assert(true);
  }

  test void checksTrailingSevenArgumentSource() {
    long opcode = 31744;
    long leading = 218893066;
    long trailing = 387323156;
    long source = 6;
    long decoded = voidCallSource(opcode, leading, trailing, source);
    assert(decoded == 22);
  }
}
