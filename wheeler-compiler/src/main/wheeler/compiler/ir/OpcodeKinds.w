//! Classifies canonical core opcode families without owning their identities.

module wheeler.compiler.opcode_kinds;

import wheeler.compiler.opcodes;

classical class OpcodeKinds {
  /// Reports whether an opcode mutates one global with a constant operand.
  public boolean isGlobalConstantOpcode(long opcode) {
    if (opcode == OPCODE_ADD_CONST) {
      return true;
    }

    if (opcode == OPCODE_SUB_CONST) {
      return true;
    }

    return opcode == OPCODE_XOR_CONST;
  }

  /// Reports whether an opcode exchanges one implicit result slot.
  public boolean isResultFillOpcode(long opcode) {
    if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
      return true;
    }

    if (opcode == OPCODE_RESULT_FILL_SOURCE) {
      return true;
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY) {
      return true;
    }

    return opcode == OPCODE_RESULT_FILL_BINARY_SOURCES;
  }

  /// Reports whether an opcode names one signed result binary operation.
  public boolean isResultBinaryOperation(long opcode) {
    if (opcode == OPCODE_LOCAL_ADD) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_SUB) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_XOR) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_MUL) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_DIV) {
      return true;
    }

    if (opcode == OPCODE_LOCAL_MOD) {
      return true;
    }

    return opcode == OPCODE_LOCAL_AND;
  }

  /// Reports whether an opcode applies the bounded three-local math shape.
  public boolean isLocalMathOpcode(long opcode) {
    if (isResultBinaryOperation(opcode)) {
      return true;
    }

    return opcode == OPCODE_LOCAL_ROTR32;
  }
}
