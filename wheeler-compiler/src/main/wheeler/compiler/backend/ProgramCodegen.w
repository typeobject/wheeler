//! Encodes bounded helper bodies and reversible signed result slots.

module wheeler.compiler.program_codegen;

import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.codegen;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.helper_abi;
import wheeler.compiler.helper_signatures;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_types;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_local_copy_kinds;
import wheeler.compiler.resolved_local_pair_assertions;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_long_operations;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.two_argument_call_kinds;

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
  private const long RESULT_SLOT_FUNCTION = 0;
  private const long RESULT_SLOT_ARGUMENT_BASE = 0;
  private const long RESULT_SLOT_ARGUMENT_COUNT = 0;
  private const long RESULT_SLOT_ONE_ARGUMENT_LOCALS = 5;
  private const long RESULT_SLOT_ONE_ARGUMENT_CODE_LENGTH = 160;
  private const long RESULT_SLOT_TWO_ARGUMENT_LOCALS = 7;
  private const long RESULT_SLOT_TWO_ARGUMENT_CODE_LENGTH = 208;
  private const long MAX_RESULT_ARGUMENT_LOCALS = 4;
  private const long MAX_HELPER_CALLS = 2;
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

  private long resultBinaryOperation(long opcode) {
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

  private long resultPreludeOperation(long opcode) {
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

  private long writeResultSlotSourceBody(
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

  private long writeResultSlotBinaryBody(
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

  private long writeResultSlotBinarySourcesBody(
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

  private long writeSequence(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long[64] operands,
    long[64] secondaryOperands,
    long count,
    long localBase,
    long firstCallStatement,
    long firstCallFunction,
    long secondCallStatement,
    long secondCallFunction,
    long thirdCallStatement,
    long thirdCallFunction
  ) {
    long index = 0;
    long instructionBase = 0;
    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      long callFunction = -1;
      if (index == firstCallStatement) {
        callFunction = firstCallFunction;
      }

      if (index == secondCallStatement) {
        callFunction = secondCallFunction;
      }

      if (index == thirdCallStatement) {
        callFunction = thirdCallFunction;
      }

      cursor = writeStatement(
        output,
        cursor,
        opcodes[index],
        operands[index],
        secondaryOperands[index],
        localBase,
        instructionBase,
        callFunction
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
      long resultStatement = helperAt(program, 0).resultStatement;
      long resultOpcode = helperAt(program, 0).opcodes[resultStatement];
      if (resolvedLocalLongPair(resultOpcode)) {
        long preludeOperation = resultPreludeOperation(resultOpcode);
        cursor = writeResultSlotBinarySourcesBody(
          output,
          cursor,
          helperLocalBase,
          resolvedLocalLongPairSource(resultOpcode),
          preludeOperation,
          helperAt(program, 0).operands[resultStatement]
        );
        return writeResultSlotBinarySourcesBody(
          output,
          cursor,
          helperLocalBase,
          resolvedLocalLongPairSource(resultOpcode),
          preludeOperation,
          helperAt(program, 0).operands[resultStatement]
        );
      }

      if (resolvedLocalLongBinary(resultOpcode)) {
        long binaryPreludeOperation = resultPreludeOperation(resultOpcode);
        cursor = writeResultSlotBinaryBody(
          output,
          cursor,
          helperLocalBase,
          resolvedLocalLongBinarySource(resultOpcode),
          binaryPreludeOperation,
          helperAt(program, 0).operands[resultStatement]
        );
        return writeResultSlotBinaryBody(
          output,
          cursor,
          helperLocalBase,
          resolvedLocalLongBinarySource(resultOpcode),
          binaryPreludeOperation,
          helperAt(program, 0).operands[resultStatement]
        );
      }

      if (resolvedSignedLocalReturn(resultOpcode)) {
        long resultSource = resolvedLocalReturnSource(resultOpcode);
        cursor = writeResultSlotSourceBody(output, cursor, helperLocalBase, resultSource);
        return writeResultSlotSourceBody(output, cursor, helperLocalBase, resultSource);
      }

      if (returnLocalPairStatement(resultOpcode)) {
        long sourceOperation = resultBinaryOperation(resultOpcode);
        cursor = writeResultSlotBinarySourcesBody(
          output,
          cursor,
          helperLocalBase,
          helperAt(program, 0).secondaryOperands[resultStatement],
          sourceOperation,
          helperAt(program, 0).operands[resultStatement]
        );
        return writeResultSlotBinarySourcesBody(
          output,
          cursor,
          helperLocalBase,
          helperAt(program, 0).secondaryOperands[resultStatement],
          sourceOperation,
          helperAt(program, 0).operands[resultStatement]
        );
      }

      if (returnLocalBinaryStatement(resultOpcode)) {
        long operation = resultBinaryOperation(resultOpcode);
        cursor = writeResultSlotBinaryBody(
          output,
          cursor,
          helperLocalBase,
          helperAt(program, 0).secondaryOperands[resultStatement],
          operation,
          helperAt(program, 0).operands[resultStatement]
        );
        return writeResultSlotBinaryBody(
          output,
          cursor,
          helperLocalBase,
          helperAt(program, 0).secondaryOperands[resultStatement],
          operation,
          helperAt(program, 0).operands[resultStatement]
        );
      }

      cursor = writeResultSlotBody(
        output,
        cursor,
        helperLocalBase,
        helperAt(program, 0).operands[resultStatement]
      );
      return writeResultSlotBody(
        output,
        cursor,
        helperLocalBase,
        helperAt(program, 0).operands[resultStatement]
      );
    }

    if (helperAt(program, 0).kind == HELPER_REVERSIBLE) {
      cursor = writeReversibleSequence(
        output,
        cursor,
        helperAt(program, 0).opcodes,
        helperAt(program, 0).operands,
        helperAt(program, 0).statementCount,
        false
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
      cursor = writeReversibleSequence(
        output,
        cursor,
        helperAt(program, 0).opcodes,
        helperAt(program, 0).operands,
        helperAt(program, 0).statementCount,
        true
      );
      return writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
    }

    cursor = writeSequence(
      output,
      cursor,
      helperAt(program, 0).opcodes,
      helperAt(program, 0).operands,
      helperAt(program, 0).secondaryOperands,
      helperAt(program, 0).statementCount,
      helperLocalBase,
      helperAt(program, 0).firstCallStatement,
      helperAt(program, 0).firstCallFunction,
      helperAt(program, 0).secondCallStatement,
      helperAt(program, 0).secondCallFunction,
      helperAt(program, 0).thirdCallStatement,
      helperAt(program, 0).thirdCallFunction
    );
    if (HELPER_REVERSIBLE < helperAt(program, 0).kind) {
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
        instructionBase,
        -1
      );
      instructionBase += statementInstructionCount(program.statementOpcodes[0]);
    }

    if (helperAt(program, 0).kind == HELPER_REVERSIBLE) {
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
          instructionBase,
          -1
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
          instructionBase,
          -1
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
        0,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1
      );
    }

    cursor = writeHelperBody(output, cursor, program, helperLocalBase, resultSlotProgram);
    if (1 < program.helperCount) {
      long helper = 1;
      while (helper < program.helperCount) limit MAX_SCALAR_HELPERS {
        HelperBody body = helperAt(program, helper);
        cursor = writeSequence(
          output,
          cursor,
          body.opcodes,
          body.operands,
          body.secondaryOperands,
          body.statementCount,
          parameterCountForHelper(body.kind),
          body.firstCallStatement,
          body.firstCallFunction,
          body.secondCallStatement,
          body.secondCallFunction,
          body.thirdCallStatement,
          body.thirdCallFunction
        );
        helper += 1;
      }

      return cursor;
    }

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

    if (HELPER_REVERSIBLE < helperAt(program, 0).kind) {
      return writeSequence(
        output,
        cursor,
        program.statementOpcodes,
        program.statementOperands,
        program.statementSecondaryOperands,
        program.statementCount,
        0,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1
      );
    }

    return writeVoidHelperEntry(output, cursor, program);
  }
}
