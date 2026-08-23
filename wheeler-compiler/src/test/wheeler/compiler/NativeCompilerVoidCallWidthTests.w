//! Checks both physical ordinary void-call width decoders through native package tests.

module wheeler.compiler.tests.native_compiler_void_call_widths;

import wheeler.compiler.void_call_widths;

classical class NativeCompilerVoidCallWidthTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentCodeWidth() {
    long width = voidCallCodeLength(31744);
    assert(width == 368);
  }

  test void checksSevenArgumentInstructionWidth() {
    long width = voidCallInstructionCount(31744);
    assert(width == 15);
  }
}
