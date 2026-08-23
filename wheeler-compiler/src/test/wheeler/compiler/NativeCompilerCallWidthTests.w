//! Checks physical nested call-assignment width decoders through native package tests.

module wheeler.compiler.tests.native_compiler_call_widths;

import wheeler.compiler.assignment_call_code_widths;
import wheeler.compiler.assignment_call_instruction_widths;
import wheeler.compiler.assignment_call_local_widths;

classical class NativeCompilerCallWidthTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentCodeWidth() {
    long width = assignmentCallCodeLength(933);
    assert(width == 400);
  }

  test void checksSevenArgumentInstructionWidth() {
    long width = assignmentCallInstructionCount(933);
    assert(width == 16);
  }

  test void checksSevenArgumentLocalWidth() {
    long width = assignmentCallLocalCount(933);
    assert(width == 15);
  }
}
