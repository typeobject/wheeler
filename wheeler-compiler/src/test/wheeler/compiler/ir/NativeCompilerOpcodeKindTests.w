//! Checks physical opcode-family classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_opcode_kinds;

import wheeler.compiler.opcode_kinds;

classical class NativeCompilerOpcodeKindTests {
  entry void main() {
    assert(true);
  }

  test void checksGlobalConstantOpcode() {
    boolean present = isGlobalConstantOpcode(258);
    assert(present);
  }

  test void checksResultFillOpcode() {
    boolean present = isResultFillOpcode(523);
    assert(present);
  }

  test void checksResultBinaryOpcode() {
    boolean present = isResultBinaryOperation(1046);
    assert(present);
  }

  test void checksLocalMathOpcode() {
    boolean present = isLocalMathOpcode(1047);
    assert(present);
  }
}
