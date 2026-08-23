//! Checks physical source and resolved void-call local widths through native package tests.

module wheeler.compiler.tests.native_compiler_void_call_source_widths;

import wheeler.compiler.void_call_source_widths;

classical class NativeCompilerVoidCallSourceWidthTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentSourceLocalWidth() {
    long width = voidCallLocalCount(925);
    assert(width == 14);
  }

  test void checksSevenArgumentResolvedLocalWidth() {
    long width = voidCallLocalCount(31744);
    assert(width == 14);
  }
}
