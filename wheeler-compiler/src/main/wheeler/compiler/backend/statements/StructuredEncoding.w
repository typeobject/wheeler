//! Encodes structured, storage, call, conditional, and assertion statements.

module wheeler.compiler.structured_statement_encoding;

import wheeler.compiler.backend_scalar_encoding;
import wheeler.compiler.conditionals;
import wheeler.compiler.encoding;
import wheeler.compiler.literal_comparison_operations;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.loop_codegen;
import wheeler.compiler.mutation_codegen;
import wheeler.compiler.opcodes;
import wheeler.compiler.owned_storage_codegen;
import wheeler.compiler.owned_utf8_copy_codegen;
import wheeler.compiler.owned_utf8_copy_loops;
import wheeler.compiler.resolved_boolean_literal_assertions;
import wheeler.compiler.resolved_less_than_assertions;
import wheeler.compiler.resolved_literal_comparison_kinds;
import wheeler.compiler.resolved_local_conditional_kinds;
import wheeler.compiler.resolved_local_conditional_operands;
import wheeler.compiler.resolved_local_conditional_sources;
import wheeler.compiler.resolved_local_loop_kinds;
import wheeler.compiler.resolved_local_pair_assertions;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;

classical class StructuredStatementEncoding {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  /// Writes one structured statement or returns minus one when another owner applies.
  public long writeStructuredStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long instructionBase,
    long callFunction
  ) {
    if (ownedUtf8CopyLoop(opcode)) {
      return writeOwnedUtf8CopyLoop(
        output,
        cursor,
        opcode,
        operand,
        secondaryOperand,
        localBase,
        instructionBase
      );
    }

    if (resolvedLocalWhile(opcode)) {
      return writeLocalWhile(
        output,
        cursor,
        opcode,
        operand,
        secondaryOperand,
        localBase,
        instructionBase
      );
    }

    long storageCursor = writeOwnedStorageStatement(
      output,
      cursor,
      opcode,
      operand,
      secondaryOperand,
      localBase
    );
    if (-1 < storageCursor) {
      return storageCursor;
    }

    long mutationCursor = writeMutationStatement(output, cursor, opcode, operand, localBase);
    if (-1 < mutationCursor) {
      return mutationCursor;
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

    if (opcode == STATEMENT_ASSERT_GLOBAL_CONSTANT) {
      return writeGlobalLiteralAssertion(output, cursor, operand, localBase);
    }

    if (resolvedBooleanLiteralAssertion(opcode)) {
      return writeLocalLiteralAssertion(
        output,
        cursor,
        resolvedBooleanLiteralAssertionSource(opcode),
        operand,
        localBase,
        OPCODE_LOCAL_EQ
      );
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

    if (resolvedLiteralLessThanAssertion(opcode)) {
      return writeLocalLiteralAssertion(
        output,
        cursor,
        resolvedLiteralLessThanAssertionSource(opcode),
        operand,
        localBase,
        OPCODE_LOCAL_LT
      );
    }

    if (resolvedLocalLiteralAssignmentConditional(opcode)) {
      boolean reversed = resolvedLocalLiteralAssignmentReversed(opcode);
      long firstSource = resolvedLocalLiteralAssignmentSource(opcode);
      long firstOpcode = OPCODE_LOCAL_MOVE;
      if (reversed) {
        firstSource = secondaryOperand;
        firstOpcode = OPCODE_LOCAL_CONST;
      }

      cursor = writeInstructionHeader(output, cursor, firstOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      if (firstOpcode == OPCODE_LOCAL_CONST) {
        cursor = writeSignedLittleEndian(output, cursor, firstSource, U64);
      } else {
        cursor = writeUnsignedLittleEndian(output, cursor, firstSource, U64);
      }

      long secondSource = secondaryOperand;
      long secondOpcode = OPCODE_LOCAL_CONST;
      if (reversed) {
        secondSource = resolvedLocalLiteralAssignmentSource(opcode);
        secondOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, secondOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      if (secondOpcode == OPCODE_LOCAL_CONST) {
        cursor = writeSignedLittleEndian(output, cursor, secondSource, U64);
      } else {
        cursor = writeUnsignedLittleEndian(output, cursor, secondSource, U64);
      }

      long comparisonOpcode = OPCODE_LOCAL_EQ;
      if (resolvedLocalLiteralAssignmentLessThan(opcode)) {
        comparisonOpcode = OPCODE_LOCAL_LT;
      }

      cursor = writeInstructionHeader(output, cursor, comparisonOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, instructionBase + 7, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        resolvedLocalLiteralAssignmentValue(opcode),
        U64
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, instructionBase + 7, U64);
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

    return -1;
  }
}
