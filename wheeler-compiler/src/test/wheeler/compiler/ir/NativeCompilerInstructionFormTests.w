//! Checks physical instruction operand forms through native package tests.

module wheeler.compiler.tests.native_compiler_instruction_forms;

import wheeler.compiler.instruction_forms;

classical class NativeCompilerInstructionFormTests {
  entry void main() {
    assert(true);
  }

  test void checksRecordProjectionOperandCount() {
    long count = expectedOperandCount(1281);
    assert(count == 3);
  }
}
