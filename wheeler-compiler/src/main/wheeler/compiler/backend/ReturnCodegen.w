//! Encodes bounded typed helper return statements.

module wheeler.compiler.return_codegen;

import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.early_return_sources;
import wheeler.compiler.encoding;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_early_comparison_kinds;
import wheeler.compiler.resolved_early_result_kinds;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;

classical class ReturnCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long writeReturnScalarOperand(
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

  /// Writes a typed helper return, or reports that the opcode is not a return.
  public long writeReturnStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long instructionBase,
    long callFunction
  ) {
    if (returnHelperCallArity(opcode) == 0) {
      assert(-1 < callFunction);
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* argumentBase= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (returnHelperCallArity(opcode) == 2) {
      assert(-1 < callFunction);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        returnHelperCallFirstSource(opcode) - RETURN_HELPER_CALL_TWO_SOURCE_OFFSET,
        U64
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        returnHelperCallSecondSource(opcode),
        U64
      );
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
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    }

    if (resolvedReturnHelperCall(opcode)) {
      assert(-1 < callFunction);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        returnHelperCallFirstSource(opcode),
        U64
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (resolvedEarlyHelperReturn(opcode)) {
      assert(-1 < callFunction);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, earlyHelperReturnSource(opcode), U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, instructionBase + 7, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeSignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, instructionBase + 7, U64);
    }

    if (resolvedEarlyComparisonReturn(opcode)) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        earlyComparisonReturnSource(opcode),
        U64
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      long guardComparisonOpcode = OPCODE_LOCAL_EQ;
      if (resolvedEarlyLessReturn(opcode)) {
        guardComparisonOpcode = OPCODE_LOCAL_LT;
      }

      cursor = writeInstructionHeader(output, cursor, guardComparisonOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      long returnTarget = instructionBase + 7;
      if (resolvedEarlyComputedReturn(opcode)) {
        returnTarget = instructionBase + 9;
      }

      cursor = writeUnsignedLittleEndian(output, cursor, returnTarget, U64);
      if (resolvedEarlyComputedReturn(opcode)) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
        cursor = writeUnsignedLittleEndian(
          output,
          cursor,
          earlyComparisonReturnSource(opcode),
          U64
        );
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
        cursor = writeSignedLittleEndian(output, cursor, secondaryOperand, U64);
        long computedOpcode = OPCODE_LOCAL_SUB;
        if (resolvedEarlyRemainderReturn(opcode)) {
          computedOpcode = OPCODE_LOCAL_MOD;
        }

        cursor = writeInstructionHeader(output, cursor, computedOpcode, FORM_TERNARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
        cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
        cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
        return writeUnsignedLittleEndian(output, cursor, returnTarget, U64);
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeSignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, returnTarget, U64);
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (returnComparisonStatement(opcode)) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      long rightOpcode = OPCODE_LOCAL_CONST;
      if (returnComparisonLocalRight(opcode)) {
        rightOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, rightOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeReturnScalarOperand(output, cursor, rightOpcode, secondaryOperand);
      long comparisonOpcode = OPCODE_LOCAL_EQ;
      if (returnSignedLessThanStatement(opcode)) {
        comparisonOpcode = OPCODE_LOCAL_LT;
      }

      cursor = writeInstructionHeader(output, cursor, comparisonOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      long comparisonResult = localBase + 2;
      if (returnInequalityStatement(opcode)) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
        cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, comparisonResult, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
        comparisonResult = localBase + 4;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, comparisonResult, U64);
    }

    if (returnLocalPairStatement(opcode)) {
      long returnPairOpcode = OPCODE_LOCAL_ADD;
      if (opcode == STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_SUB;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_MUL;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_DIV;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_MOD;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_XOR;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_AND;
      }

      long leftCopy = localBase;
      long rightCopy = localBase + 1;
      long result = localBase + 2;

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, leftCopy, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, rightCopy, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, returnPairOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, result, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, leftCopy, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, rightCopy, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, result, U64);
    }

    if (returnLocalBinaryStatement(opcode)) {
      long returnOpcode = OPCODE_LOCAL_ADD;
      if (opcode == STATEMENT_RETURN_LOCAL_SUB_NAMED) {
        returnOpcode = OPCODE_LOCAL_SUB;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MUL_NAMED) {
        returnOpcode = OPCODE_LOCAL_MUL;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_DIV_NAMED) {
        returnOpcode = OPCODE_LOCAL_DIV;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MOD_NAMED) {
        returnOpcode = OPCODE_LOCAL_MOD;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_XOR_NAMED) {
        returnOpcode = OPCODE_LOCAL_XOR;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_AND_NAMED) {
        returnOpcode = OPCODE_LOCAL_AND;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, returnOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (resolvedLocalReturn(opcode)) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        resolvedLocalReturnSource(opcode),
        U64
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    boolean literalReturn = opcode == STATEMENT_RETURN_LONG;
    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      literalReturn = true;
    }

    if (literalReturn) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    return -1;
  }
}
