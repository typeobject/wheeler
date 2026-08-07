//! Emits exact guarded UTF-8 owner-result helper calls.

module wheeler.compiler.early_utf8_call_codegen;

import wheeler.compiler.call_arguments;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;

classical class EarlyUtf8CallCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
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

  /// Emits one guarded UTF-8 call, or reports another owner.
  public long writeEarlyUtf8Call(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long localBase,
    long instructionBase,
    long callFunction,
    long firstSourceType,
    long secondSourceType
  ) {
    if (earlyUtf8Call(opcode)) {} else {
      return -1;
    }

    assert(-1 < callFunction);
    long firstSource = operand / EARLY_UTF8_CALL_SOURCE_SCALE;
    long secondSource = operand % EARLY_UTF8_CALL_SOURCE_SCALE;
    cursor = writeMove(
      output,
      cursor,
      OPCODE_LOCAL_MOVE,
      localBase,
      earlyUtf8ConditionLocal(opcode)
    );
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeSignedLittleEndian(output, cursor, earlyUtf8Selector(opcode), U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, instructionBase + 11, U64);
    cursor = writeMove(output, cursor, OPCODE_LOCAL_MOVE, localBase + 3, firstSource);
    cursor = writeMove(output, cursor, OPCODE_LOCAL_MOVE, localBase + 4, secondSource);
    cursor = writeMove(
      output,
      cursor,
      callArgumentOpcode(firstSourceType),
      localBase + 5,
      localBase + 3
    );
    cursor = writeMove(
      output,
      cursor,
      callArgumentOpcode(secondSourceType),
      localBase + 6,
      localBase + 4
    );
    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 7, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 7, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, instructionBase + 11, U64);
  }
}
