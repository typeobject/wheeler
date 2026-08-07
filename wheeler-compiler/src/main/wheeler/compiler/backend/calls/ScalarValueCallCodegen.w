//! Encodes bounded scalar value-call statement forms.

module wheeler.compiler.scalar_value_call_codegen;

import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_arguments;
import wheeler.compiler.encoding;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.opcodes;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.wide_local_calls;

classical class ScalarValueCallCodegen {
  private const long FOUR_ARGUMENT_CALL_ARITY = 4;
  private const long FOUR_ARGUMENT_CALL_BASE_OFFSET = 4;
  private const long FOUR_ARGUMENT_CALL_RESULT_OFFSET = 8;
  private const long FOUR_ARGUMENT_CALL_FINAL_OFFSET = 9;
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
    long callFunction,
    long sourceType
  ) {
    cursor = writeInstructionHeader(output, cursor, sourceOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeScalarOperand(output, cursor, sourceOpcode, source);
    long argumentOpcode = callArgumentOpcode(sourceType);
    cursor = writeInstructionHeader(output, cursor, argumentOpcode, FORM_BINARY);
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

  private long writeFourLocalArgumentCall(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long firstSource,
    long secondSource,
    long localBase,
    long callFunction,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType
  ) {
    long thirdSource = fourArgumentCallThirdSource(opcode);
    long fourthSource = fourArgumentCallFourthSource(opcode);
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
    cursor = writeUnsignedLittleEndian(output, cursor, fourthSource, U64);
    cursor = writeInstructionHeader(
      output,
      cursor,
      callArgumentOpcode(firstSourceType),
      FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeInstructionHeader(
      output,
      cursor,
      callArgumentOpcode(secondSourceType),
      FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(
      output,
      cursor,
      callArgumentOpcode(thirdSourceType),
      FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 6, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeInstructionHeader(
      output,
      cursor,
      callArgumentOpcode(fourthSourceType),
      FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 7, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
    cursor = writeUnsignedLittleEndian(
      output,
      cursor,
      localBase + FOUR_ARGUMENT_CALL_BASE_OFFSET,
      U64
    );
    cursor = writeUnsignedLittleEndian(output, cursor, FOUR_ARGUMENT_CALL_ARITY, U64);
    cursor = writeUnsignedLittleEndian(
      output,
      cursor,
      localBase + FOUR_ARGUMENT_CALL_RESULT_OFFSET,
      U64
    );
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(
      output,
      cursor,
      localBase + FOUR_ARGUMENT_CALL_FINAL_OFFSET,
      U64
    );
    return writeUnsignedLittleEndian(
      output,
      cursor,
      localBase + FOUR_ARGUMENT_CALL_RESULT_OFFSET,
      U64
    );
  }

  private long writeThreeLocalArgumentCall(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long firstSource,
    long secondSource,
    long localBase,
    long callFunction,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType
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
    cursor = writeInstructionHeader(
      output,
      cursor,
      callArgumentOpcode(firstSourceType),
      FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeInstructionHeader(
      output,
      cursor,
      callArgumentOpcode(secondSourceType),
      FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(
      output,
      cursor,
      callArgumentOpcode(thirdSourceType),
      FORM_BINARY
    );
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

  private long writePackedWideLocalCall(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long callFunction,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType,
    long fifthSourceType,
    long sixthSourceType,
    long seventhSourceType
  ) {
    long arity = wideLocalCallArity(opcode);
    long argument = 0;
    while (argument < arity) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        wideLocalCallSource(opcode, operand, secondaryOperand, argument),
        U64
      );
      argument += 1;
    }

    argument = 0;
    while (argument < arity) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
      long sourceType = callSourceType(
        argument,
        firstSourceType,
        secondSourceType,
        thirdSourceType,
        fourthSourceType,
        fifthSourceType,
        sixthSourceType,
        seventhSourceType
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        callArgumentOpcode(sourceType),
        FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity + argument, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      argument += 1;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, arity, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity * 2, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity * 2 + 1, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase + arity * 2, U64);
  }

  /// Writes one bounded scalar value call, or reports that it owns no opcode.
  public long writeScalarValueCallStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long callFunction,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType,
    long fifthSourceType,
    long sixthSourceType,
    long seventhSourceType
  ) {
    if (packedWideLocalCall(opcode)) {
      return writePackedWideLocalCall(
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
    }

    if (fourArgumentCallStatement(opcode)) {
      return writeFourLocalArgumentCall(
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
        fourthSourceType
      );
    }

    if (threeArgumentCallStatement(opcode)) {
      return writeThreeLocalArgumentCall(
        output,
        cursor,
        opcode,
        operand,
        secondaryOperand,
        localBase,
        callFunction,
        firstSourceType,
        secondSourceType,
        thirdSourceType
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
      long firstTransferOpcode = callArgumentOpcode(firstSourceType);
      cursor = writeInstructionHeader(output, cursor, firstTransferOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      long secondTransferOpcode = callArgumentOpcode(secondSourceType);
      cursor = writeInstructionHeader(output, cursor, secondTransferOpcode, FORM_BINARY);
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
        callFunction,
        firstSourceType
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
        callFunction,
        firstSourceType
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

  /// Writes one scalar-only value call from the untyped entry profile.
  public long writeSignedScalarValueCallStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long callFunction
  ) {
    return writeScalarValueCallStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase,
      callFunction,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED,
      TYPE_SIGNED
    );
  }
}
