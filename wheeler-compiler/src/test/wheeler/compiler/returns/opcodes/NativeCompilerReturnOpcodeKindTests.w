//! Checks physical scalar return-opcode selection through native package tests.

module wheeler.compiler.tests.native_compiler_return_opcode_kinds;

import wheeler.compiler.return_opcode_kinds;

classical class NativeCompilerReturnOpcodeKindTests {
  entry void main() {
    assert(true);
  }

  test void selectsFinalSignedAmbiguousOpcode() {
    long opcode = signedAmbiguousOpcode(865);
    assert(opcode == 875);
  }

  test void selectsFinalLiteralComparisonOpcode() {
    long opcode = literalComparisonOpcode(877);
    assert(opcode == 876);
  }

  test void selectsFinalLiteralArithmeticOpcode() {
    long opcode = literalReturnOpcode(861);
    assert(opcode == 860);
  }
}
