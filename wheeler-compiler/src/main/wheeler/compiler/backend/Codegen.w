//! Encodes the bounded bootstrap IR as canonical Wheeler bytecode.

module wheeler.compiler.codegen;

import wheeler.compiler.conditionals;
import wheeler.compiler.encoding;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class Codegen {
  private long writeLocalComparison(
    borrow mut bytes output,
    long cursor,
    long sourceLocal,
    long rightLocal,
    long localBase,
    long rightOpcode,
    long comparisonOpcode
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, sourceLocal, 8);
    cursor = writeInstructionHeader(output, cursor, rightOpcode, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    if (rightOpcode == OPCODE_LOCAL_CONST) {
      cursor = writeSignedLittleEndian(output, cursor, rightLocal, 8);
    } else {
      cursor = writeUnsignedLittleEndian(output, cursor, rightLocal, 8);
    }

    cursor = writeInstructionHeader(output, cursor, comparisonOpcode, 3);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
  }

  private long writeLocalPairAssertion(
    borrow mut bytes output,
    long cursor,
    long leftLocal,
    long rightLocal,
    long localBase,
    long comparisonOpcode
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, leftLocal, 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, rightLocal, 8);
    cursor = writeInstructionHeader(output, cursor, comparisonOpcode, 3);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
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

  /// Writes canonical local type codes for one parsed statement.
  public long writeStatementLocalTypes(borrow mut bytes output, long cursor, long opcode) {
    long count = statementLocalCount(opcode);
    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedLocalPairAssertion(opcode)) {
      long assertedType = TYPE_BOOLEAN;
      if (resolvedLocalPairAssertionSigned(opcode)) {
        assertedType = TYPE_SIGNED;
      }

      cursor = writeUnsignedLittleEndian(output, cursor, assertedType, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, assertedType, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedLiteralComparisonConditional(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      if (literalComparisonConditionalAssignment(opcode)) {
        return cursor;
      }

      return writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
    }

    if (resolvedLocalConditional(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      if (resolvedLocalConditionalNegated(opcode)) {
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      }

      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      if (resolvedLocalConditionalAssignment(opcode)) {
        return cursor;
      }

      return writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
    }

    boolean comparison = resolvedLocalEquality(opcode);
    if (resolvedLocalLongLessThan(opcode)) {
      comparison = true;
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      comparison = true;
    }

    if (comparison) {
      long sourceType = TYPE_BOOLEAN;
      if (resolvedLocalEqualitySigned(opcode)) {
        sourceType = TYPE_SIGNED;
      }

      if (resolvedLocalLongLessThan(opcode)) {
        sourceType = TYPE_SIGNED;
      }

      if (resolvedLocalLiteralComparison(opcode)) {
        sourceType = TYPE_SIGNED;
      }

      cursor = writeUnsignedLittleEndian(output, cursor, sourceType, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, sourceType, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedLocalLongAssertion(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    long typeCode = TYPE_SIGNED;
    if (resolvedLocalBooleanCopy(opcode)) {
      typeCode = TYPE_BOOLEAN;
    }

    if (resolvedLocalBooleanNot(opcode)) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      typeCode = TYPE_BOOLEAN;
    }

    long local = 0;
    while (local < count) limit 4 {
      cursor = writeUnsignedLittleEndian(output, cursor, typeCode, 4);
      local += 1;
    }

    return cursor;
  }

  /// Returns the encoded byte width of one parsed statement.
  public long statementCodeLength(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return 64;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return 40;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      return 96;
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      return 104;
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      return 96;
    }

    if (resolvedLocalPairAssertion(opcode)) {
      return 96;
    }

    if (resolvedLiteralComparisonConditional(opcode)) {
      if (literalComparisonConditionalAssignment(opcode)) {
        return 168;
      }

      return 224;
    }

    if (resolvedLocalConditional(opcode)) {
      if (resolvedLocalConditionalAssignment(opcode)) {
        if (resolvedLocalConditionalNegated(opcode)) {
          return 168;
        }

        return 112;
      }

      if (resolvedLocalConditionalNegated(opcode)) {
        return 224;
      }

      return 168;
    }

    if (resolvedLocalLongLessThan(opcode)) {
      return 104;
    }

    if (resolvedLocalEquality(opcode)) {
      return 104;
    }

    if (resolvedLocalBooleanCopy(opcode)) {
      return 48;
    }

    if (resolvedLocalBooleanNot(opcode)) {
      return 104;
    }

    if (resolvedLocalLongPair(opcode)) {
      return 104;
    }

    if (resolvedLocalLongBinary(opcode)) {
      return 104;
    }

    if (resolvedLocalLongCopy(opcode)) {
      return 48;
    }

    if (resolvedLocalLongAssertion(opcode)) {
      return 96;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      return 24;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return 40;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return 96;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return 40;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return 48;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return 48;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return 104;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return 48;
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      return 48;
    }

    if (0 < opcode) {
      return 104;
    }

    return 0;
  }

  /// Returns the instruction count emitted by one parsed statement.
  public long statementInstructionCount(long opcode) {
    long length = statementCodeLength(opcode);
    if (length == 24) {
      return 1;
    }

    if (length == 40) {
      return 2;
    }

    if (length == 48) {
      return 2;
    }

    if (length == 64) {
      return 2;
    }

    if (length == 112) {
      return 5;
    }

    if (length == 168) {
      return 7;
    }

    if (length == 224) {
      return 9;
    }

    if (0 < length) {
      return 4;
    }

    return 0;
  }

  /// Writes `globalUpdate` into caller-owned bounded output.
  public long writeGlobalUpdate(borrow mut bytes output, long cursor, long opcode, long operand) {
    cursor = writeInstructionHeader(output, cursor, globalOpcode(opcode), 2);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
    return writeSignedLittleEndian(output, cursor, operand, 8);
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
      2
    );
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
    return writeSignedLittleEndian(output, cursor, operand, 8);
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
    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeSignedLittleEndian(output, cursor, operand, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeSignedLittleEndian(output, cursor, operand, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeSignedLittleEndian(output, cursor, secondaryOperand, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
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

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        resolvedLiteralComparisonConditionalSource(opcode),
        8
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeSignedLittleEndian(output, cursor, secondaryOperand, 8);
      cursor = writeInstructionHeader(output, cursor, guardComparisonOpcode, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, comparisonEndInstruction, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
      cursor = writeSignedLittleEndian(output, cursor, operand, 8);
      if (comparisonAssignment) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
        cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, 1);
        return writeUnsignedLittleEndian(output, cursor, comparisonEndInstruction, 8);
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeInstructionHeader(output, cursor, comparisonUpdateOpcode, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, 1);
      return writeUnsignedLittleEndian(output, cursor, comparisonEndInstruction, 8);
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

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, guardLocal, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, conditionLocal, 8);
      if (resolvedLocalConditionalNegated(opcode)) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
        cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, /* width= */ 8);
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, 3);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
        guardLocal = localBase + 2;
        valueLocal = localBase + 3;
        globalLocal = localBase + 4;
        endInstruction = instructionBase + 9;
        if (assignment) {
          endInstruction = instructionBase + 7;
        }
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, guardLocal, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, endInstruction, 8);
      long valueOpcode = OPCODE_LOCAL_CONST;
      if (resolvedLocalConditionalValue(opcode)) {
        valueOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, valueOpcode, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, valueLocal, 8);
      cursor = writeSignedLittleEndian(output, cursor, operand, 8);
      if (assignment) {
        cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
        cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
        cursor = writeUnsignedLittleEndian(output, cursor, valueLocal, 8);
        cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, 1);
        return writeUnsignedLittleEndian(output, cursor, endInstruction, 8);
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeInstructionHeader(output, cursor, conditionalOpcode, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, valueLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeUnsignedLittleEndian(output, cursor, globalLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, 1);
      return writeUnsignedLittleEndian(output, cursor, endInstruction, 8);
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_EQ, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      return writeSignedLittleEndian(output, cursor, operand, 8);
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      long literalComparisonOpcode = OPCODE_LOCAL_LT;
      if (resolvedLocalLiteralEquality(opcode)) {
        literalComparisonOpcode = OPCODE_LOCAL_EQ;
      }

      return writeLocalComparison(
        output,
        cursor,
        resolvedLocalLiteralComparisonSource(opcode),
        operand,
        localBase,
        OPCODE_LOCAL_CONST,
        literalComparisonOpcode
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
        OPCODE_LOCAL_EQ
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
        OPCODE_LOCAL_LT
      );
    }

    if (resolvedLocalBooleanCopy(opcode)) {
      long booleanSourceLocal = opcode - STATEMENT_LOCAL_BOOLEAN_COPY_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, booleanSourceLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (resolvedLocalBooleanNot(opcode)) {
      long negatedSourceLocal = opcode - STATEMENT_LOCAL_BOOLEAN_NOT_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, negatedSourceLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, /* width= */ 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
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

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, pairSourceLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, 8);
      cursor = writeInstructionHeader(output, cursor, pairOpcode, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
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

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, binarySourceLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeSignedLittleEndian(output, cursor, operand, 8);
      cursor = writeInstructionHeader(output, cursor, binaryOpcode, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    }

    if (resolvedLocalLongCopy(opcode)) {
      long sourceLocal = opcode - STATEMENT_LOCAL_LONG_COPY_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, sourceLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (resolvedLocalLongAssertion(opcode)) {
      long assertedLocal = opcode - STATEMENT_ASSERT_LOCAL_LONG_BASE;
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, assertedLocal, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeSignedLittleEndian(output, cursor, operand, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    long operandOpcode = OPCODE_LOCAL_CONST;
    if (namedGlobalUpdate(opcode)) {
      operandOpcode = OPCODE_LOCAL_MOVE;
    }

    cursor = writeInstructionHeader(output, cursor, operandOpcode, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeSignedLittleEndian(output, cursor, operand, 8);
    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, /* width= */ 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 1, /* width= */ 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    }

    if (opcode == STATEMENT_ASSIGN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
    cursor = writeInstructionHeader(output, cursor, localGlobalUpdateOpcode(opcode), 3);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
    return writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
  }

  /// Writes `functionDescriptor` into caller-owned bounded output.
  public long writeFunctionDescriptor(
    borrow mut bytes output,
    long cursor,
    long id,
    long name,
    long forwardOffset,
    long forwardLength,
    long flags,
    long inverseOffset,
    long inverseLength,
    long localCount,
    long typeOffset
  ) {
    cursor = writeUnsignedLittleEndian(output, cursor, id, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, name, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, flags, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, forwardOffset, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, forwardLength, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, inverseOffset, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, inverseLength, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 4);
    cursor = writeUnsignedLittleEndian(output, cursor, localCount, 4);
    return writeUnsignedLittleEndian(output, cursor, typeOffset, 4);
  }
}
