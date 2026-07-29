//! Encodes the bounded bootstrap IR as canonical Wheeler bytecode.

module wheeler.compiler.codegen;

import wheeler.compiler.call_forms;
import wheeler.compiler.conditionals;
import wheeler.compiler.encoding;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.return_codegen;
import wheeler.compiler.scalar_opcodes;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class Codegen {
  /// Aliases named instruction forms for compact emitter calls.
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
  /// Aliases the named instruction operand width for compact emitter calls.
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

  private long writeLocalComparison(
    borrow mut bytes output,
    long cursor,
    long sourceLocal,
    long rightLocal,
    long localBase,
    long rightOpcode,
    long comparisonOpcode,
    boolean negated
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, sourceLocal, U64);
    cursor = writeInstructionHeader(output, cursor, rightOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    if (rightOpcode == OPCODE_LOCAL_CONST) {
      cursor = writeSignedLittleEndian(output, cursor, rightLocal, U64);
    } else {
      cursor = writeUnsignedLittleEndian(output, cursor, rightLocal, U64);
    }

    cursor = writeInstructionHeader(output, cursor, comparisonOpcode, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    long comparisonResult = localBase + 2;
    long resultLocal = localBase + 3;
    if (negated) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, comparisonResult, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      comparisonResult = localBase + 4;
      resultLocal = localBase + 5;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, resultLocal, U64);
    return writeUnsignedLittleEndian(output, cursor, comparisonResult, U64);
  }

  private long writeLocalPairAssertion(
    borrow mut bytes output,
    long cursor,
    long leftLocal,
    long rightLocal,
    long localBase,
    long comparisonOpcode
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, leftLocal, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, rightLocal, U64);
    cursor = writeInstructionHeader(output, cursor, comparisonOpcode, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
  }

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

  /// Maps a prior-local global update to its typed local operation.
  public long localGlobalUpdateOpcode(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
      return OPCODE_LOCAL_ADD;
    }

    if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      return OPCODE_LOCAL_SUB;
    }

    if (opcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED) {
      return OPCODE_LOCAL_XOR;
    }

    return opcode;
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

  /// Writes `statement` into caller-owned bounded output.
  public long writeStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long instructionBase
  ) {
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
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    }

    if (oneArgumentCallNamed(opcode)) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    boolean literalOneArgumentCall = oneArgumentCallStatement(opcode);
    if (oneArgumentCallNamed(opcode)) {
      literalOneArgumentCall = false;
    }

    if (literalOneArgumentCall) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    boolean zeroArgumentCall = opcode == STATEMENT_LOCAL_CALL_NAMED;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      zeroArgumentCall = true;
    }

    if (zeroArgumentCall) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    long returnCursor = writeReturnStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase
    );
    if (-1 < returnCursor) {
      return returnCursor;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (resolvedLocalPairAssertion(opcode)) {
      return writeLocalPairAssertion(
        output,
        cursor,
        resolvedLocalPairAssertionSource(opcode),
        operand,
        localBase,
        OPCODE_LOCAL_EQ
      );
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      return writeLocalPairAssertion(
        output,
        cursor,
        opcode - STATEMENT_ASSERT_LONG_LT_BASE,
        operand,
        localBase,
        OPCODE_LOCAL_LT
      );
    }

    if (resolvedLiteralComparisonConditional(opcode)) {
      long comparisonUpdateOpcode = OPCODE_LOCAL_ADD;
      if (literalComparisonConditionalSubtract(opcode)) {
        comparisonUpdateOpcode = OPCODE_LOCAL_SUB;
      }

      if (literalComparisonConditionalXor(opcode)) {
        comparisonUpdateOpcode = OPCODE_LOCAL_XOR;
      }

      long guardComparisonOpcode = OPCODE_LOCAL_EQ;
      if (literalComparisonConditionalLessThan(opcode)) {
        guardComparisonOpcode = OPCODE_LOCAL_LT;
      }

      boolean comparisonAssignment = literalComparisonConditionalAssignment(opcode);
      long comparisonEndInstruction = instructionBase + 9;
      if (comparisonAssignment) {
        comparisonEndInstruction = instructionBase + 7;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        resolvedLiteralComparisonConditionalSource(opcode),
        U64
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, guardComparisonOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, comparisonEndInstruction, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      if (comparisonAssignment) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
        cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
        return writeUnsignedLittleEndian(output, cursor, comparisonEndInstruction, U64);
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeInstructionHeader(output, cursor, comparisonUpdateOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, comparisonEndInstruction, U64);
    }

    if (resolvedLocalConditional(opcode)) {
      long conditionLocal = resolvedLocalConditionalSource(opcode);
      long conditionalOpcode = OPCODE_LOCAL_ADD;
      if (resolvedLocalConditionalSubtract(opcode)) {
        conditionalOpcode = OPCODE_LOCAL_SUB;
      }

      if (resolvedLocalConditionalXor(opcode)) {
        conditionalOpcode = OPCODE_LOCAL_XOR;
      }

      boolean assignment = resolvedLocalConditionalAssignment(opcode);
      long guardLocal = localBase;
      long valueLocal = localBase + 1;
      long globalLocal = localBase + 2;
      long endInstruction = instructionBase + 7;
      if (assignment) {
        endInstruction = instructionBase + 5;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, guardLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, conditionLocal, U64);
      if (resolvedLocalConditionalNegated(opcode)) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        guardLocal = localBase + 2;
        valueLocal = localBase + 3;
        globalLocal = localBase + 4;
        endInstruction = instructionBase + 9;
        if (assignment) {
          endInstruction = instructionBase + 7;
        }
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, guardLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, endInstruction, U64);
      long valueOpcode = OPCODE_LOCAL_CONST;
      if (resolvedLocalConditionalValue(opcode)) {
        valueOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, valueOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, valueLocal, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      if (assignment) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, FORM_BINARY);
        cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, valueLocal, U64);
        cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
        return writeUnsignedLittleEndian(output, cursor, endInstruction, U64);
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeInstructionHeader(output, cursor, conditionalOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, valueLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, endInstruction, U64);
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_EQ, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      return writeSignedLittleEndian(output, cursor, operand, U64);
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      long literalComparisonOpcode = OPCODE_LOCAL_LT;
      if (resolvedLocalLiteralEquality(opcode)) {
        literalComparisonOpcode = OPCODE_LOCAL_EQ;
      }

      if (resolvedLocalLiteralInequality(opcode)) {
        literalComparisonOpcode = OPCODE_LOCAL_EQ;
      }

      return writeLocalComparison(
        output,
        cursor,
        resolvedLocalLiteralComparisonSource(opcode),
        operand,
        localBase,
        OPCODE_LOCAL_CONST,
        literalComparisonOpcode,
        /* negated= */ resolvedLocalLiteralInequality(opcode)
      );
    }

    if (resolvedLocalEquality(opcode)) {
      return writeLocalComparison(
        output,
        cursor,
        resolvedLocalEqualitySource(opcode),
        operand,
        localBase,
        OPCODE_LOCAL_MOVE,
        OPCODE_LOCAL_EQ,
        /* negated= */ false
      );
    }

    if (resolvedLocalInequality(opcode)) {
      return writeLocalComparison(
        output,
        cursor,
        resolvedLocalInequalitySource(opcode),
        operand,
        localBase,
        OPCODE_LOCAL_MOVE,
        OPCODE_LOCAL_EQ,
        /* negated= */ true
      );
    }

    if (resolvedLocalLongLessThan(opcode)) {
      return writeLocalComparison(
        output,
        cursor,
        opcode - STATEMENT_LOCAL_LONG_LT_BASE,
        operand,
        localBase,
        OPCODE_LOCAL_MOVE,
        OPCODE_LOCAL_LT,
        /* negated= */ false
      );
    }

    if (resolvedLocalBooleanCopy(opcode)) {
      long booleanSourceLocal = opcode - STATEMENT_LOCAL_BOOLEAN_COPY_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, booleanSourceLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (resolvedLocalBooleanNot(opcode)) {
      long negatedSourceLocal = opcode - STATEMENT_LOCAL_BOOLEAN_NOT_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, negatedSourceLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (resolvedLocalLongPair(opcode)) {
      long pairSourceLocal = resolvedLocalLongPairSource(opcode);
      long pairOpcode = OPCODE_LOCAL_ADD;
      if (STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE - 1 < opcode) {
        pairOpcode = OPCODE_LOCAL_SUB;
      }

      if (STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE - 1 < opcode) {
        pairOpcode = OPCODE_LOCAL_XOR;
      }

      if (STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE - 1 < opcode) {
        pairOpcode = OPCODE_LOCAL_MUL;
      }

      if (STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE - 1 < opcode) {
        pairOpcode = OPCODE_LOCAL_DIV;
      }

      if (STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE - 1 < opcode) {
        pairOpcode = OPCODE_LOCAL_MOD;
      }

      if (STATEMENT_LOCAL_LONG_AND_LOCALS_BASE - 1 < opcode) {
        pairOpcode = OPCODE_LOCAL_AND;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, pairSourceLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, pairOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (resolvedLocalLongBinary(opcode)) {
      long binarySourceLocal = resolvedLocalLongBinarySource(opcode);
      long binaryOpcode = OPCODE_LOCAL_ADD;
      if (STATEMENT_LOCAL_LONG_SUB_BASE - 1 < opcode) {
        binaryOpcode = OPCODE_LOCAL_SUB;
      }

      if (STATEMENT_LOCAL_LONG_XOR_BASE - 1 < opcode) {
        binaryOpcode = OPCODE_LOCAL_XOR;
      }

      if (STATEMENT_LOCAL_LONG_MUL_BASE - 1 < opcode) {
        binaryOpcode = OPCODE_LOCAL_MUL;
      }

      if (STATEMENT_LOCAL_LONG_DIV_BASE - 1 < opcode) {
        binaryOpcode = OPCODE_LOCAL_DIV;
      }

      if (STATEMENT_LOCAL_LONG_MOD_BASE - 1 < opcode) {
        binaryOpcode = OPCODE_LOCAL_MOD;
      }

      if (STATEMENT_LOCAL_LONG_AND_BASE - 1 < opcode) {
        binaryOpcode = OPCODE_LOCAL_AND;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, binarySourceLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, binaryOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (resolvedLocalLongCopy(opcode)) {
      long sourceLocal = opcode - STATEMENT_LOCAL_LONG_COPY_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, sourceLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (resolvedLocalLongAssertion(opcode)) {
      long assertedLocal = opcode - STATEMENT_ASSERT_LOCAL_LONG_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, assertedLocal, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    long operandOpcode = OPCODE_LOCAL_CONST;
    if (namedGlobalUpdate(opcode)) {
      operandOpcode = OPCODE_LOCAL_MOVE;
    }

    cursor = writeInstructionHeader(output, cursor, operandOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeSignedLittleEndian(output, cursor, operand, U64);
    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (opcode == STATEMENT_ASSIGN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
    cursor = writeInstructionHeader(
      output,
      cursor,
      localGlobalUpdateOpcode(opcode),
      FORM_TERNARY
    );
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
  }

}
