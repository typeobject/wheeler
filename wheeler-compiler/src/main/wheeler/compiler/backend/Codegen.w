//! Encodes the bounded bootstrap IR as canonical Wheeler bytecode.

module wheeler.compiler.codegen;

import wheeler.compiler.assignment_call_codegen;
import wheeler.compiler.borrowed_intrinsic_codegen;
import wheeler.compiler.early_utf8_call_codegen;
import wheeler.compiler.encoding;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_statement_encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.return_codegen;
import wheeler.compiler.scalar_value_call_codegen;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.structured_statement_encoding;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_codegen;

classical class Codegen {
  /// Aliases the binary instruction form for global update emission.
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  /// Aliases the named instruction operand width for compact emitter calls.
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  /// Maps a parsed global update to its canonical bytecode opcode.
  public long globalOpcode(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD) {
      return OPCODE_ADD_CONST;
    }

    if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
      return OPCODE_ADD_CONST;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return OPCODE_SUB_CONST;
    }

    if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      return OPCODE_SUB_CONST;
    }

    return OPCODE_XOR_CONST;
  }

  /// Maps a forward global opcode to its exact inverse opcode.
  public long inverseGlobalOpcode(long opcode) {
    if (opcode == OPCODE_ADD_CONST) {
      return OPCODE_SUB_CONST;
    }

    if (opcode == OPCODE_SUB_CONST) {
      return OPCODE_ADD_CONST;
    }

    return OPCODE_XOR_CONST;
  }

  /// Writes `globalUpdate` into caller-owned bounded output.
  public long writeGlobalUpdate(borrow mut bytes output, long cursor, long opcode, long operand) {
    cursor = writeInstructionHeader(output, cursor, globalOpcode(opcode), FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
    return writeSignedLittleEndian(output, cursor, operand, U64);
  }

  /// Writes `inverseGlobalUpdate` into caller-owned bounded output.
  public long writeInverseGlobalUpdate(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand
  ) {
    cursor = writeInstructionHeader(
      output,
      cursor,
      inverseGlobalOpcode(globalOpcode(opcode)),
      FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
    return writeSignedLittleEndian(output, cursor, operand, U64);
  }

  /// Writes a helper statement with canonical borrowed-call argument opcodes.
  public long writeHelperStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long instructionBase,
    long callFunction,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType,
    long fifthSourceType,
    long sixthSourceType,
    long seventhSourceType
  ) {
    long earlyUtf8Cursor = writeEarlyUtf8Call(
      output,
      cursor,
      opcode,
      operand,
      localBase,
      instructionBase,
      callFunction,
      firstSourceType,
      secondSourceType
    );
    if (-1 < earlyUtf8Cursor) {
      return earlyUtf8Cursor;
    }

    long voidCallCursor = writeVoidCallStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      callFunction,
      firstSourceType,
      secondSourceType,
      thirdSourceType,
      fourthSourceType,
      fifthSourceType,
      sixthSourceType,
      seventhSourceType
    );
    if (-1 < voidCallCursor) {
      return voidCallCursor;
    }

    long intrinsicCursor = writeBorrowedIntrinsicStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      firstSourceType
    );
    if (-1 < intrinsicCursor) {
      return intrinsicCursor;
    }

    long returnCursor = writeReturnStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      instructionBase,
      callFunction,
      firstSourceType,
      secondSourceType,
      thirdSourceType,
      fourthSourceType,
      fifthSourceType,
      sixthSourceType,
      seventhSourceType
    );
    if (-1 < returnCursor) {
      return returnCursor;
    }

    long assignmentCallCursor = writeAssignmentCallStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      callFunction,
      firstSourceType,
      secondSourceType,
      thirdSourceType,
      fourthSourceType,
      fifthSourceType,
      sixthSourceType,
      seventhSourceType
    );
    if (-1 < assignmentCallCursor) {
      return assignmentCallCursor;
    }

    long valueCallCursor = writeScalarValueCallStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      callFunction,
      firstSourceType,
      secondSourceType,
      thirdSourceType,
      fourthSourceType,
      fifthSourceType,
      sixthSourceType,
      seventhSourceType
    );
    if (-1 < valueCallCursor) {
      return valueCallCursor;
    }

    return writeStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      instructionBase,
      callFunction
    );
  }

  /// Writes `statement` into caller-owned bounded output.
  public long writeStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long instructionBase,
    long callFunction
  ) {
    long valueCallCursor = writeSignedScalarValueCallStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      callFunction
    );
    if (-1 < valueCallCursor) {
      return valueCallCursor;
    }

    long returnCursor = writeReturnStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      instructionBase,
      callFunction,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED
    );
    if (-1 < returnCursor) {
      return returnCursor;
    }

    long structuredCursor = writeStructuredStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      instructionBase,
      callFunction
    );
    if (-1 < structuredCursor) {
      return structuredCursor;
    }

    return writeRemainingStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      instructionBase,
      callFunction
    );
  }

}
