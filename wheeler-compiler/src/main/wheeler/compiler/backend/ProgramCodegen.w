//! Encodes bounded helper bodies and reversible signed result slots.

module wheeler.compiler.program_codegen;

import wheeler.compiler.codegen;
import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_types;
import wheeler.compiler.opcodes;
import wheeler.compiler.scalar_opcodes;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class ProgramCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;
  private const long RESULT_SLOT_TAG_OFFSET = 0;
  private const long RESULT_SLOT_PAYLOAD_OFFSET = 1;
  private const long RESULT_VALUE_OFFSET = 2;
  private const long RESULT_SLOT_ENTRY_LOCALS = 3;
  private const long RESULT_SLOT_ENTRY_CODE_LENGTH = 112;
  private const long RESULT_SLOT_ENTRY_INSTRUCTIONS = 4;
  private const long RESULT_SLOT_FUNCTION = 0;
  private const long RESULT_SLOT_ARGUMENT_BASE = 0;
  private const long RESULT_SLOT_ARGUMENT_COUNT = 0;
  private const long MAX_HELPER_CALLS = 2;
  private const long LOGICAL_RESULT_CALL_LOCALS = 2;

  private boolean resultCall(long opcode) {
    return opcode == STATEMENT_LOCAL_CALL_NAMED;
  }

  private long physicalResultSlotOpcode(long opcode) {
    if (resolvedLocalLongAssertion(opcode)) {
      long source = opcode - STATEMENT_ASSERT_LOCAL_LONG_BASE;
      long priorResultSlots = (source + RESULT_SLOT_LOGICAL_RESULT_LOCAL)
        / LOGICAL_RESULT_CALL_LOCALS;
      return STATEMENT_ASSERT_LOCAL_LONG_BASE + source + priorResultSlots;
    }

    return opcode;
  }

  /// Returns the local width for one result-slot entry statement.
  public long resultSlotEntryLocalCount(long opcode) {
    if (resultCall(opcode)) {
      return RESULT_SLOT_ENTRY_LOCALS;
    }

    return statementLocalCount(opcode);
  }

  /// Returns the encoded width for one result-slot entry statement.
  public long resultSlotEntryCodeLength(long opcode) {
    if (resultCall(opcode)) {
      return RESULT_SLOT_ENTRY_CODE_LENGTH;
    }

    return statementCodeLength(opcode);
  }

  /// Returns the instruction width for one result-slot entry statement.
  public long resultSlotEntryInstructionCount(long opcode) {
    if (resultCall(opcode)) {
      return RESULT_SLOT_ENTRY_INSTRUCTIONS;
    }

    return statementInstructionCount(opcode);
  }

  /// Writes one reversible constant-result body.
  public long writeResultSlotBody(borrow mut bytes output, long cursor, long value) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_RESULT_FILL_CONSTANT, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, RESULT_SLOT_TAG_OFFSET, U64);
    cursor = writeSignedLittleEndian(output, cursor, value, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_RESULT_SLOT, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, RESULT_SLOT_TAG_OFFSET, U64);
  }

  /// Writes local types for one result-slot entry statement.
  public long writeResultSlotEntryLocalTypes(borrow mut bytes output, long cursor, long opcode) {
    if (resultCall(opcode)) {
      cursor = writeBooleanLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      return writeSignedLocalType(output, cursor);
    }

    return writeStatementLocalTypes(output, cursor, opcode);
  }

  private long writeResultCall(borrow mut bytes output, long cursor, long localBase) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + RESULT_SLOT_TAG_OFFSET, U64);
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 0, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(
      output,
      cursor,
      localBase + RESULT_SLOT_PAYLOAD_OFFSET,
      U64
    );
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 0, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_RESULT_SLOT, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, RESULT_SLOT_FUNCTION, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, RESULT_SLOT_ARGUMENT_BASE, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, RESULT_SLOT_ARGUMENT_COUNT, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + RESULT_SLOT_TAG_OFFSET, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + RESULT_VALUE_OFFSET, U64);
    return writeUnsignedLittleEndian(
      output,
      cursor,
      localBase + RESULT_SLOT_PAYLOAD_OFFSET,
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
        cursor = writeResultCall(output, cursor, localBase);
      } else {
        cursor = writeStatement(
          output,
          cursor,
          physicalResultSlotOpcode(opcode),
          operands[statement],
          secondaryOperands[statement],
          localBase,
          instructionBase
        );
      }

      localBase += resultSlotEntryLocalCount(opcode);
      instructionBase += resultSlotEntryInstructionCount(opcode);
      statement += 1;
    }

    return cursor;
  }

  private long writeSequence(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long[64] operands,
    long[64] secondaryOperands,
    long count,
    long localBase
  ) {
    long index = 0;
    long instructionBase = 0;
    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeStatement(
        output,
        cursor,
        opcodes[index],
        operands[index],
        secondaryOperands[index],
        localBase,
        instructionBase
      );
      localBase += statementLocalCount(opcodes[index]);
      instructionBase += statementInstructionCount(opcodes[index]);
      index += 1;
    }

    return cursor;
  }

  private long writeReversibleSequence(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long[64] operands,
    long count,
    boolean inverse
  ) {
    long index = 0;
    if (inverse) {
      index = count;
      while (0 < index) limit MAX_MINIMAL_STATEMENTS {
        index -= 1;
        cursor = writeInverseGlobalUpdate(output, cursor, opcodes[index], operands[index]);
      }

      return cursor;
    }

    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      cursor = writeGlobalUpdate(output, cursor, opcodes[index], operands[index]);
      index += 1;
    }

    return cursor;
  }

  private long writeHelperBody(
    borrow mut bytes output,
    long cursor,
    MinimalProgram program,
    long helperLocalBase,
    boolean resultSlotProgram
  ) {
    if (resultSlotProgram) {
      cursor = writeResultSlotBody(output, cursor, program.helperOperands[0]);
      return writeResultSlotBody(output, cursor, program.helperOperands[0]);
    }

    if (program.helperKind == HELPER_REVERSIBLE) {
      cursor = writeReversibleSequence(
        output,
        cursor,
        program.helperOpcodes,
        program.helperOperands,
        program.helperStatementCount,
        false
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
      cursor = writeReversibleSequence(
        output,
        cursor,
        program.helperOpcodes,
        program.helperOperands,
        program.helperStatementCount,
        true
      );
      return writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
    }

    cursor = writeSequence(
      output,
      cursor,
      program.helperOpcodes,
      program.helperOperands,
      program.helperSecondaryOperands,
      program.helperStatementCount,
      helperLocalBase
    );
    if (HELPER_REVERSIBLE < program.helperKind) {
      return cursor;
    }

    return writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
  }

  private long writeVoidHelperEntry(borrow mut bytes output, long cursor, MinimalProgram program) {
    long instructionBase = 0;
    long helperCall = 0;
    while (helperCall < program.helperCallCount) limit MAX_HELPER_CALLS {
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL, INSTRUCTION_FORM_UNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* function= */ 0, ENCODING_WIDTH_U64);
      helperCall += 1;
      instructionBase += 1;
    }

    if (program.preReverseStatementCount == 1) {
      cursor = writeStatement(
        output,
        cursor,
        program.statementOpcodes[0],
        program.statementOperands[0],
        program.statementSecondaryOperands[0],
        0,
        instructionBase
      );
      instructionBase += statementInstructionCount(program.statementOpcodes[0]);
    }

    if (program.helperKind == HELPER_REVERSIBLE) {
      long helperUncall = 0;
      while (helperUncall < program.helperCallCount) limit MAX_HELPER_CALLS {
        cursor = writeInstructionHeader(output, cursor, OPCODE_UNCALL, INSTRUCTION_FORM_UNARY);
        cursor = writeUnsignedLittleEndian(
          output,
          cursor,
          /* function= */ 0,
          ENCODING_WIDTH_U64
        );
        helperUncall += 1;
        instructionBase += 1;
      }
    }

    if (program.preReverseStatementCount == 0) {
      if (0 < program.statementCount) {
        cursor = writeStatement(
          output,
          cursor,
          program.statementOpcodes[0],
          program.statementOperands[0],
          program.statementSecondaryOperands[0],
          0,
          instructionBase
        );
      }
    } else {
      if (1 < program.statementCount) {
        cursor = writeStatement(
          output,
          cursor,
          program.statementOpcodes[1],
          program.statementOperands[1],
          program.statementSecondaryOperands[1],
          statementLocalCount(program.statementOpcodes[0]),
          instructionBase
        );
      }
    }

    return cursor;
  }

  /// Writes all bounded function code before the entry halt.
  public long writeProgramCode(
    borrow mut bytes output,
    long cursor,
    MinimalProgram program,
    long helperLocalBase,
    boolean resultSlotProgram
  ) {
    if (program.helperCount == 0) {
      return writeSequence(
        output,
        cursor,
        program.statementOpcodes,
        program.statementOperands,
        program.statementSecondaryOperands,
        program.statementCount,
        0
      );
    }

    cursor = writeHelperBody(output, cursor, program, helperLocalBase, resultSlotProgram);
    if (resultSlotProgram) {
      return writeResultSlotEntrySequence(
        output,
        cursor,
        program.statementOpcodes,
        program.statementOperands,
        program.statementSecondaryOperands,
        program.statementCount
      );
    }

    if (HELPER_REVERSIBLE < program.helperKind) {
      return writeSequence(
        output,
        cursor,
        program.statementOpcodes,
        program.statementOperands,
        program.statementSecondaryOperands,
        program.statementCount,
        0
      );
    }

    return writeVoidHelperEntry(output, cursor, program);
  }
}
