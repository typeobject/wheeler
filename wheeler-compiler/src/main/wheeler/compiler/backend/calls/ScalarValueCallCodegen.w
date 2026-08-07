//! Encodes bounded scalar value-call statement forms.

module wheeler.compiler.scalar_value_call_codegen;

import wheeler.compiler.call_argument_sources;
import wheeler.compiler.encoding;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.opcodes;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.two_argument_call_kinds;

classical class ScalarValueCallCodegen {
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long writeScalarOperand(
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

  private long writeOneArgumentCall(
    borrow mut bytes output,
    long cursor,
    long sourceOpcode,
    long source,
    long localBase,
    long callFunction
  ) {
    cursor = writeInstructionHeader(output, cursor, sourceOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeScalarOperand(output, cursor, sourceOpcode, source);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
  }

  private long writeThreeLocalArgumentCall(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long firstSource,
    long secondSource,
    long localBase,
    long callFunction
  ) {
    long thirdSource = threeArgumentThirdSource(opcode);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, firstSource, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, secondSource, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, thirdSource, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 3, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 6, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 7, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase + 6, U64);
  }

  /// Writes one bounded scalar value call, or reports that it owns no opcode.
  public long writeScalarValueCallStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long callFunction
  ) {
    if (threeArgumentCallStatement(opcode)) {
      return writeThreeLocalArgumentCall(
        output,
        cursor,
        opcode,
        operand,
        secondaryOperand,
        localBase,
        callFunction
      );
    }

    if (twoArgumentCallStatement(opcode)) {
      long firstArgumentOpcode = OPCODE_LOCAL_CONST;
      if (twoArgumentCallFirstNamed(opcode)) {
        firstArgumentOpcode = OPCODE_LOCAL_MOVE;
      }

      long secondArgumentOpcode = OPCODE_LOCAL_CONST;
      if (twoArgumentCallSecondNamed(opcode)) {
        secondArgumentOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, firstArgumentOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeScalarOperand(output, cursor, firstArgumentOpcode, operand);
      cursor = writeInstructionHeader(output, cursor, secondArgumentOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeScalarOperand(output, cursor, secondArgumentOpcode, secondaryOperand);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    }

    if (oneArgumentCallNamed(opcode)) {
      return writeOneArgumentCall(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        operand,
        localBase,
        callFunction
      );
    }

    boolean literalOneArgumentCall = oneArgumentCallStatement(opcode);
    if (oneArgumentCallNamed(opcode)) {
      literalOneArgumentCall = false;
    }

    if (literalOneArgumentCall) {
      return writeOneArgumentCall(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        operand,
        localBase,
        callFunction
      );
    }

    boolean zeroArgumentCall = opcode == STATEMENT_LOCAL_CALL_NAMED;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      zeroArgumentCall = true;
    }

    if (zeroArgumentCall) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* argumentBase= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    return -1;
  }
}
