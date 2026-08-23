//! Checks the physical packed assignment-call source decoder through native package tests.

module wheeler.compiler.tests.native_compiler_call_operand;

import wheeler.compiler.assignment_call_operands;

classical class NativeCompilerCallOperandTests {
  entry void main() {
    assert(true);
  }

  test void checksLeadingSevenArgumentSource() {
    long opcode = 933;
    long leading = 218893066;
    long trailing = 2828841;
    long source = 0;
    long decoded = assignmentCallSource(opcode, leading, trailing, source);
    assert(decoded == 10);
  }
}
