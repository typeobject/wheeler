//! Encodes bounded reversible result-slot entry functions.

module wheeler.compiler.result_slot_codegen;

import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.codegen;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_type_encoding;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_local_copy_kinds;
import wheeler.compiler.resolved_local_pair_assertions;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_long_operations;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.signed_return_statements;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_local_types;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.type_codes;

classical class ResultSlotCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;
  private const long RESULT_SLOT_TAG_OFFSET = 0;
  private const long RESULT_SLOT_PAYLOAD_OFFSET = 1;
  private const long RESULT_VALUE_OFFSET = 2;
  private const long RESULT_SLOT_ENTRY_LOCALS = 3;
  private const long RESULT_SLOT_ENTRY_CODE_LENGTH = 112;
  private const long RESULT_SLOT_FUNCTION = 0;
  private const long RESULT_SLOT_ARGUMENT_BASE = 0;
  private const long RESULT_SLOT_ARGUMENT_COUNT = 0;
  private const long RESULT_SLOT_ONE_ARGUMENT_LOCALS = 5;
  private const long RESULT_SLOT_ONE_ARGUMENT_CODE_LENGTH = 160;
  private const long RESULT_SLOT_TWO_ARGUMENT_LOCALS = 7;
  private const long RESULT_SLOT_TWO_ARGUMENT_CODE_LENGTH = 208;
  private const long MAX_RESULT_ARGUMENT_LOCALS = 4;
  private const long LOGICAL_ASSERTION_LOCALS = 3;

  private boolean resultCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    return twoArgumentSignedResultCall(opcode);
  }

  private long resultSlotsBeforeSource(long[64] opcodes, long statement, long source) {
    long prior = 0;
    long logicalBase = 0;
    long resultSlots = 0;
    while (prior < statement) limit MAX_MINIMAL_STATEMENTS {
      if (resultCall(opcodes[prior])) {
        if (logicalBase < source) {
          resultSlots += 1;
        }

        logicalBase += statementLocalCount(opcodes[prior]);
      } else {
        logicalBase += LOGICAL_ASSERTION_LOCALS;
      }

      prior += 1;
    }

    return resultSlots;
  }

  private long physicalResultSlotSource(long[64] opcodes, long statement, long source) {
    return source + resultSlotsBeforeSource(opcodes, statement, source);
  }

  private long physicalResultSlotOpcode(long[64] opcodes, long statement, long opcode) {
    if (resolvedLocalLongAssertion(opcode)) {
      long source = opcode - STATEMENT_ASSERT_LOCAL_LONG_BASE;
      return STATEMENT_ASSERT_LOCAL_LONG_BASE + physicalResultSlotSource(
        opcodes,
        statement,
        source
      );
    }

    if (resolvedLocalPairAssertionSigned(opcode)) {
      long pairSource = resolvedLocalPairAssertionSource(opcode);
      return STATEMENT_ASSERT_LONG_PAIR_BASE + physicalResultSlotSource(
        opcodes,
        statement,
        pairSource
      );
    }

    return opcode;
  }

  private long physicalResultSlotOperand(
    long[64] opcodes,
    long statement,
    long opcode,
    long operand
  ) {
    if (resolvedLocalPairAssertionSigned(opcode)) {
      return physicalResultSlotSource(opcodes, statement, operand);
    }

    return operand;
  }

  /// Returns the local width for one result-slot entry statement.
  public long resultSlotEntryLocalCount(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return RESULT_SLOT_ENTRY_LOCALS;
    }

    if (oneArgumentCallStatement(opcode)) {
      return RESULT_SLOT_ONE_ARGUMENT_LOCALS;
    }

    if (resultCall(opcode)) {
      return RESULT_SLOT_TWO_ARGUMENT_LOCALS;
    }

    return statementLocalCount(opcode);
  }

  /// Returns the encoded width for one result-slot entry statement.
  public long resultSlotEntryCodeLength(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return RESULT_SLOT_ENTRY_CODE_LENGTH;
    }

    if (oneArgumentCallStatement(opcode)) {
      return RESULT_SLOT_ONE_ARGUMENT_CODE_LENGTH;
    }

    if (resultCall(opcode)) {
      return RESULT_SLOT_TWO_ARGUMENT_CODE_LENGTH;
    }

    return statementCodeLength(opcode);
  }

  /// Returns the instruction width for one result-slot entry statement.
  public long resultSlotEntryInstructionCount(long opcode) {
    if (resultCall(opcode)) {
      return statementInstructionCount(opcode) + 2;
    }

    return statementInstructionCount(opcode);
  }

  /// Writes one reversible constant-result body.
  public long writeResultSlotBody(
    borrow mut bytes output,
    long cursor,
    long resultSlot,
    long value
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_RESULT_FILL_CONSTANT, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
    cursor = writeSignedLittleEndian(output, cursor, value, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_RESULT_SLOT, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
  }

  /// Maps one result expression to its canonical binary operation.
  public long resultBinaryOperation(long opcode) {
    if (opcode == STATEMENT_RETURN_LOCAL_SUB_NAMED) {
      return OPCODE_LOCAL_SUB;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED) {
      return OPCODE_LOCAL_SUB;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MUL_NAMED) {
      return OPCODE_LOCAL_MUL;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED) {
      return OPCODE_LOCAL_MUL;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_DIV_NAMED) {
      return OPCODE_LOCAL_DIV;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED) {
      return OPCODE_LOCAL_DIV;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MOD_NAMED) {
      return OPCODE_LOCAL_MOD;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
      return OPCODE_LOCAL_MOD;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_XOR_NAMED) {
      return OPCODE_LOCAL_XOR;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED) {
      return OPCODE_LOCAL_XOR;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_AND_NAMED) {
      return OPCODE_LOCAL_AND;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED) {
      return OPCODE_LOCAL_AND;
    }

    return OPCODE_LOCAL_ADD;
  }

  /// Maps one result expression to the operation used by its checked prelude.
  public long resultPreludeOperation(long opcode) {
    long operation = OPCODE_LOCAL_ADD;
    if (resolvedLocalLongPair(opcode)) {
      if (STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE - 1 < opcode) {
        operation = OPCODE_LOCAL_SUB;
      }

      if (STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE - 1 < opcode) {
        operation = OPCODE_LOCAL_XOR;
      }

      if (STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE - 1 < opcode) {
        operation = OPCODE_LOCAL_MUL;
      }

      if (STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE - 1 < opcode) {
        operation = OPCODE_LOCAL_DIV;
      }

      if (STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE - 1 < opcode) {
        operation = OPCODE_LOCAL_MOD;
      }

      if (STATEMENT_LOCAL_LONG_AND_LOCALS_BASE - 1 < opcode) {
        operation = OPCODE_LOCAL_AND;
      }

      return operation;
    }

    if (STATEMENT_LOCAL_LONG_SUB_BASE - 1 < opcode) {
      operation = OPCODE_LOCAL_SUB;
    }

    if (STATEMENT_LOCAL_LONG_XOR_BASE - 1 < opcode) {
      operation = OPCODE_LOCAL_XOR;
    }

    if (STATEMENT_LOCAL_LONG_MUL_BASE - 1 < opcode) {
      operation = OPCODE_LOCAL_MUL;
    }

    if (STATEMENT_LOCAL_LONG_DIV_BASE - 1 < opcode) {
      operation = OPCODE_LOCAL_DIV;
    }

    if (STATEMENT_LOCAL_LONG_MOD_BASE - 1 < opcode) {
      operation = OPCODE_LOCAL_MOD;
    }

    if (STATEMENT_LOCAL_LONG_AND_BASE - 1 < opcode) {
      operation = OPCODE_LOCAL_AND;
    }

    return operation;
  }

  /// Writes one reversible result copied from a preserved source local.
  public long writeResultSlotSourceBody(
    borrow mut bytes output,
    long cursor,
    long resultSlot,
    long source
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_RESULT_FILL_SOURCE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, source, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_RESULT_SLOT, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
  }

  /// Writes one reversible result computed from a source and immediate.
  public long writeResultSlotBinaryBody(
    borrow mut bytes output,
    long cursor,
    long resultSlot,
    long source,
    long operation,
    long immediate
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_RESULT_FILL_BINARY, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, source, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, operation, U64);
    cursor = writeSignedLittleEndian(output, cursor, immediate, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_RESULT_SLOT, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
  }

  /// Writes one reversible result computed from two preserved source locals.
  public long writeResultSlotBinarySourcesBody(
    borrow mut bytes output,
    long cursor,
    long resultSlot,
    long left,
    long operation,
    long right
  ) {
    cursor = writeInstructionHeader(
      output,
      cursor,
      OPCODE_RESULT_FILL_BINARY_SOURCES,
      FORM_QUATERNARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, left, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, operation, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, right, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_RESULT_SLOT, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
  }

  /// Writes local types for one result-slot entry statement.
  public long writeResultSlotEntryLocalTypes(borrow mut bytes output, long cursor, long opcode) {
    if (resultCall(opcode)) {
      long argumentLocal = statementLocalCount(opcode) - 2;
      long argumentIndex = 0;
      while (argumentIndex < argumentLocal) limit MAX_RESULT_ARGUMENT_LOCALS {
        cursor = writeSignedLocalType(output, cursor);
        argumentIndex += 1;
      }

      cursor = writeBooleanLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      return writeSignedLocalType(output, cursor);
    }

    return writeStatementLocalTypes(output, cursor, opcode);
  }

  private long writeResultArgument(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long statement,
    boolean named,
    long operand,
    long destination
  ) {
    long argumentOpcode = OPCODE_LOCAL_CONST;
    long argumentValue = operand;
    if (named) {
      argumentOpcode = OPCODE_LOCAL_MOVE;
      argumentValue = physicalResultSlotSource(opcodes, statement, operand);
    }

    cursor = writeInstructionHeader(output, cursor, argumentOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, destination, U64);
    if (named) {
      return writeUnsignedLittleEndian(output, cursor, argumentValue, U64);
    }

    return writeSignedLittleEndian(output, cursor, argumentValue, U64);
  }

  private long writeResultCall(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long statement,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase
  ) {
    long argumentBase = RESULT_SLOT_ARGUMENT_BASE;
    long argumentCount = RESULT_SLOT_ARGUMENT_COUNT;
    long resultSlot = localBase;
    long resultValue = localBase + RESULT_VALUE_OFFSET;
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {} else {
      if (oneArgumentCallStatement(opcode)) {
        cursor = writeResultArgument(
          output,
          cursor,
          opcodes,
          statement,
          oneArgumentCallNamed(opcode),
          operand,
          localBase
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        argumentBase = localBase + 1;
        argumentCount = 1;
        resultSlot = localBase + 2;
        resultValue = localBase + 4;
      } else {
        cursor = writeResultArgument(
          output,
          cursor,
          opcodes,
          statement,
          twoArgumentCallFirstNamed(opcode),
          operand,
          localBase
        );
        cursor = writeResultArgument(
          output,
          cursor,
          opcodes,
          statement,
          twoArgumentCallSecondNamed(opcode),
          secondaryOperand,
          localBase + 1
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        argumentBase = localBase + 2;
        argumentCount = 2;
        resultSlot = localBase + 4;
        resultValue = localBase + 6;
      }
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, resultSlot + RESULT_SLOT_TAG_OFFSET, U64);
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 0, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(
      output,
      cursor,
      resultSlot + RESULT_SLOT_PAYLOAD_OFFSET,
      U64
    );
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 0, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_RESULT_SLOT, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, RESULT_SLOT_FUNCTION, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, argumentBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, argumentCount, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, resultSlot, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, resultValue, U64);
    return writeUnsignedLittleEndian(
      output,
      cursor,
      resultSlot + RESULT_SLOT_PAYLOAD_OFFSET,
      U64
    );
  }

  /// Writes one complete result-slot entry sequence.
  public long writeResultSlotEntrySequence(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long[64] operands,
    long[64] secondaryOperands,
    long count
  ) {
    long statement = 0;
    long localBase = 0;
    long instructionBase = 0;
    while (statement < count) limit MAX_MINIMAL_STATEMENTS {
      long opcode = opcodes[statement];
      if (resultCall(opcode)) {
        cursor = writeResultCall(
          output,
          cursor,
          opcodes,
          statement,
          opcode,
          operands[statement],
          secondaryOperands[statement],
          localBase
        );
      } else {
        cursor = writeStatement(
          output,
          cursor,
          physicalResultSlotOpcode(opcodes, statement, opcode),
          physicalResultSlotOperand(opcodes, statement, opcode, operands[statement]),
          secondaryOperands[statement],
          localBase,
          instructionBase,
          -1
        );
      }

      localBase += resultSlotEntryLocalCount(opcode);
      instructionBase += resultSlotEntryInstructionCount(opcode);
      statement += 1;
    }

    return cursor;
  }

}
