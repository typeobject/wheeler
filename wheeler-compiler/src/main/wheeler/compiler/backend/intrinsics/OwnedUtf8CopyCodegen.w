//! Emits the canonical bounded UTF-8-to-owned-bytes copy loop.

module wheeler.compiler.owned_utf8_copy_codegen;

import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.owned_utf8_copy_loops;
import wheeler.compiler.storage_opcodes;

classical class OwnedUtf8CopyCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long writeMove(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long destination,
    long source
  ) {
    cursor = writeInstructionHeader(output, cursor, opcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, destination, U64);
    return writeUnsignedLittleEndian(output, cursor, source, U64);
  }

  /// Emits one resolved owned UTF-8 copy loop, or reports another owner.
  public long writeOwnedUtf8CopyLoop(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long instructionBase
  ) {
    if (ownedUtf8CopyLoop(opcode)) {} else {
      return -1;
    }

    long owner = operand / COPY_LOOP_SOURCE_SCALE;
    long utf8Source = operand % COPY_LOOP_SOURCE_SCALE;
    long length = secondaryOperand / COPY_LOOP_LIMIT_SCALE;
    long limit = secondaryOperand % COPY_LOOP_LIMIT_SCALE;
    long loopCursor = ownedUtf8CopyCursor(opcode);

    cursor = writeMove(output, cursor, OPCODE_OWNED_MOVE, localBase, owner);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeSignedLittleEndian(output, cursor, limit, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 0, U64);
    cursor = writeMove(output, cursor, OPCODE_LOCAL_MOVE, localBase + 3, loopCursor);
    cursor = writeMove(output, cursor, OPCODE_LOCAL_MOVE, localBase + 4, length);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LT, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, instructionBase + 16, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOOP_CHECK, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeMove(output, cursor, OPCODE_LOCAL_MOVE, localBase + 6, loopCursor);
    cursor = writeMove(output, cursor, OPCODE_LOCAL_MOVE, localBase + 7, utf8Source);
    cursor = writeMove(output, cursor, OPCODE_LOCAL_MOVE, localBase + 8, loopCursor);
    cursor = writeInstructionHeader(output, cursor, OPCODE_UTF8_SCALAR, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 9, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 7, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 8, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_BYTES_SET, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 6, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 9, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 10, U64);
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_ADD, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, loopCursor, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, loopCursor, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 10, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, instructionBase + 3, U64);
  }
}
