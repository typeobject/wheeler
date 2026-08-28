//! Encodes bounded helper bodies and reversible signed result slots.

module wheeler.compiler.program_codegen;

import wheeler.compiler.codegen;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.helper_abi;
import wheeler.compiler.helper_signatures;
import wheeler.compiler.helper_source_types;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_local_result_kinds;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_long_operations;
import wheeler.compiler.result_slot_codegen;
import wheeler.compiler.type_codes;

classical class ProgramCodegen {
  private const long MAX_ENTRY_HELPER_CALLS = 2;

  private long writeSequence(
    borrow mut bytes output,
    long cursor,
    long[64] opcodes,
    long[64] operands,
    long[64] secondaryOperands,
    long count,
    HelperBody body,
    boolean typedHelper,
    long localBase,
    long[64] callStatements,
    long[64] callFunctions,
    long callCount,
    long defaultCallFunction
  ) {
    long index = 0;
    long instructionBase = 0;
    while (index < count) limit MAX_MINIMAL_STATEMENTS {
      long callFunction = -1;
      long secondCallFunction = -1;
      long call = 0;
      while (call < callCount) limit MAX_SCALAR_HELPER_CALLS {
        if (index == callStatements[call]) {
          if (callFunction < 0) {
            callFunction = callFunctions[call];
          } else {
            secondCallFunction = callFunctions[call];
          }
        }

        call += 1;
      }

      if (-1 < secondCallFunction) {
        callFunction = callFunction * MAX_SCALAR_HELPERS + secondCallFunction;
      }

      if (callFunction < 0) {
        callFunction = defaultCallFunction;
      }

      long firstSourceType = TYPE_SIGNED;
      long secondSourceType = TYPE_SIGNED;
      long thirdSourceType = TYPE_SIGNED;
      long fourthSourceType = TYPE_SIGNED;
      long fifthSourceType = TYPE_SIGNED;
      long sixthSourceType = TYPE_SIGNED;
      long seventhSourceType = TYPE_SIGNED;
      boolean typedStatement = typedHelper;
      if (!typedStatement) {
        typedStatement = statementUsesDeclaredSources(body, index);
      }

      if (typedStatement) {
        long opcode = opcodes[index];
        firstSourceType = helperSourceType(
          opcode,
          operands[index],
          secondaryOperands[index],
          0,
          body
        );
        secondSourceType = helperSourceType(
          opcode,
          operands[index],
          secondaryOperands[index],
          1,
          body
        );
        thirdSourceType = helperSourceType(
          opcode,
          operands[index],
          secondaryOperands[index],
          2,
          body
        );
        fourthSourceType = helperSourceType(
          opcode,
          operands[index],
          secondaryOperands[index],
          3,
          body
        );
        fifthSourceType = helperSourceType(
          opcode,
          operands[index],
          secondaryOperands[index],
          4,
          body
        );
        sixthSourceType = helperSourceType(
          opcode,
          operands[index],
          secondaryOperands[index],
          5,
          body
        );
        seventhSourceType = helperSourceType(
          opcode,
          operands[index],
          secondaryOperands[index],
          6,
          body
        );

        cursor = writeHelperStatement(
          output,
          cursor,
          opcode,
          operands[index],
          secondaryOperands[index],
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
      } else {
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
      }

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
      helperAt(program, 0),
      true,
      helperLocalBase,
      helperAt(program, 0).callStatements,
      helperAt(program, 0).callFunctions,
      helperAt(program, 0).callCount,
      -1
    );
    if (HELPER_REVERSIBLE < helperAt(program, 0).kind) {
      return cursor;
    }

    return writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
  }

  private long writeVoidHelperEntry(borrow mut bytes output, long cursor, MinimalProgram program) {
    long instructionBase = 0;
    long helperCall = 0;
    while (helperCall < program.helperCallCount) limit MAX_ENTRY_HELPER_CALLS {
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
      while (helperUncall < program.helperCallCount) limit MAX_ENTRY_HELPER_CALLS {
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
        emptyHelperBody(),
        false,
        0,
        emptyHelperCallIdentities(),
        emptyHelperCallIdentities(),
        0,
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
          body,
          true,
          body.parameterCount,
          body.callStatements,
          body.callFunctions,
          body.callCount,
          -1
        );
        if (body.kind == HELPER_VOID) {
          cursor = writeInstructionHeader(
            output,
            cursor,
            OPCODE_RETURN,
            INSTRUCTION_FORM_NULLARY
          );
        }

        helper += 1;
      }

      if (program.library) {
        return cursor;
      }

      return writeSequence(
        output,
        cursor,
        program.statementOpcodes,
        program.statementOperands,
        program.statementSecondaryOperands,
        program.statementCount,
        entryBody(program),
        false,
        0,
        program.entryCallStatements,
        program.entryCallFunctions,
        program.entryCallCount,
        -1
      );
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
        entryBody(program),
        false,
        0,
        emptyHelperCallIdentities(),
        emptyHelperCallIdentities(),
        0,
        0
      );
    }

    return writeVoidHelperEntry(output, cursor, program);
  }
}
