//! Encodes focused checked arithmetic declarations inside structured loops.

module wheeler.compiler.closure.loop_arithmetic_instruction_encoding;

import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;

classical class LoopArithmeticInstructionEncoding {
  private const long OPERAND_LOCAL = 1;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports whether one closed body opcode belongs to this encoder.
  public boolean arithmeticBodyOpcode(long opcode) {
    if (BODY_LONG_MUL_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_LONG_MUL_LITERAL_BASE + 256) {
        return true;
      }
    }

    if (BODY_LONG_ADD_LOCAL_BASE - 1 < opcode) {
      return opcode < BODY_LONG_ADD_LOCAL_BASE + 256;
    }

    return false;
  }

  private long arithmeticSource(long opcode) {
    if (opcode < BODY_LONG_ADD_LOCAL_BASE) {
      return opcode - BODY_LONG_MUL_LITERAL_BASE;
    }

    return opcode - BODY_LONG_ADD_LOCAL_BASE;
  }

  private long arithmeticInstruction(long opcode) {
    if (opcode < BODY_LONG_ADD_LOCAL_BASE) {
      return OPCODE_LOCAL_MUL;
    }

    return OPCODE_LOCAL_ADD;
  }

  /// Reports the exact instruction count for one arithmetic declaration.
  public long arithmeticBodyInstructionCount(long opcode) {
    if (arithmeticBodyOpcode(opcode)) {
      return 4;
    }

    return -1;
  }

  /// Reports the exact byte length for one arithmetic declaration.
  public long arithmeticBodyInstructionLength(long opcode) {
    if (arithmeticBodyOpcode(opcode)) {
      return 104;
    }

    return -1;
  }

  /// Reports the exact local width for one arithmetic declaration.
  public long arithmeticBodyLocalCount(long opcode) {
    if (arithmeticBodyOpcode(opcode)) {
      return 4;
    }

    return -1;
  }

  /// Writes one checked arithmetic declaration into private code storage.
  public long writeArithmeticBodyInstruction(
    borrow mut bytes output,
    long cursor,
    long localBase,
    long opcode,
    long operandKind,
    long operand
  ) {
    if (arithmeticBodyOpcode(opcode) == false) {
      return -1;
    }

    long source = arithmeticSource(opcode);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, source, U64);
    long rightOpcode = OPCODE_LOCAL_CONST;
    if (operandKind == OPERAND_LOCAL) {
      rightOpcode = OPCODE_LOCAL_MOVE;
    }

    cursor = writeInstructionHeader(output, cursor, rightOpcode, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    if (operandKind == OPERAND_LOCAL) {
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
    } else {
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
    }

    cursor = writeInstructionHeader(
      output,
      cursor,
      arithmeticInstruction(opcode),
      INSTRUCTION_FORM_TERNARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
  }
}
