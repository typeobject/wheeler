//! Encodes scalar moves, comparisons, and assertions for the compiler backend.

module wheeler.compiler.backend_scalar_encoding;

import wheeler.compiler.encoding;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.opcodes;

classical class BackendScalarEncoding {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  /// Writes one signed literal or unsigned scalar instruction operand.
  public long writeScalarOperand(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand
  ) {
    if (opcode == OPCODE_LOCAL_CONST) {
      return writeSignedLittleEndian(output, cursor, operand, U64);
    }

    return writeUnsignedLittleEndian(output, cursor, operand, U64);
  }

  /// Encodes one local comparison and optional Boolean negation.
  public long writeLocalComparison(
    borrow mut bytes output,
    long cursor,
    long sourceLocal,
    long rightLocal,
    long localBase,
    long rightOpcode,
    long comparisonOpcode,
    boolean negated
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, sourceLocal, U64);
    cursor = writeInstructionHeader(output, cursor, rightOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    if (rightOpcode == OPCODE_LOCAL_CONST) {
      cursor = writeSignedLittleEndian(output, cursor, rightLocal, U64);
    } else {
      cursor = writeUnsignedLittleEndian(output, cursor, rightLocal, U64);
    }

    cursor = writeInstructionHeader(output, cursor, comparisonOpcode, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    long comparisonResult = localBase + 2;
    long resultLocal = localBase + 3;
    if (negated) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, comparisonResult, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      comparisonResult = localBase + 4;
      resultLocal = localBase + 5;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, resultLocal, U64);
    return writeUnsignedLittleEndian(output, cursor, comparisonResult, U64);
  }

  /// Encodes one assertion over a pair of local values.
  public long writeLocalPairAssertion(
    borrow mut bytes output,
    long cursor,
    long leftLocal,
    long rightLocal,
    long localBase,
    long comparisonOpcode
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, leftLocal, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, rightLocal, U64);
    cursor = writeInstructionHeader(output, cursor, comparisonOpcode, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
  }

  /// Encodes one assertion over a local and signed literal.
  public long writeLocalLiteralAssertion(
    borrow mut bytes output,
    long cursor,
    long leftLocal,
    long rightValue,
    long localBase,
    long comparisonOpcode
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, leftLocal, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeSignedLittleEndian(output, cursor, rightValue, U64);
    cursor = writeInstructionHeader(output, cursor, comparisonOpcode, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
  }

  /// Encodes one assertion over the scalar global and signed literal.
  public long writeGlobalLiteralAssertion(
    borrow mut bytes output,
    long cursor,
    long rightValue,
    long localBase
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeSignedLittleEndian(output, cursor, rightValue, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
  }

}
