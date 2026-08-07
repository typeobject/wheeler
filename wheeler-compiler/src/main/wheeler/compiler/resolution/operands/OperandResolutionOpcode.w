//! Selects the typed statement identity used for operand resolution.

module wheeler.compiler.operand_resolution_opcode;

import wheeler.compiler.assignment_call_kinds;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.early_return_kinds;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.local_statements;
import wheeler.compiler.named_local_assignment_kinds;
import wheeler.compiler.named_local_update_kinds;
import wheeler.compiler.named_long_operations;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.named_return_comparison_operands;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.void_call_source_forms;

classical class OperandResolutionOpcode {
  /// Selects the typed opcode used for operand resolution.
  public long operandResolutionOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    boolean ambiguousTypedStatement = oneArgumentCallNamed(opcode);
    if (earlyReturnStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (twoArgumentCallFirstNamed(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (twoArgumentCallSecondNamed(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (wideLocalCallStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (anyVoidCallSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (assignmentCallSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (returnComparisonLocalRight(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (returnLocalPairStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (localUpdateSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (localAssignmentSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (namedLongPair(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_IF_EQ_RETURN_UTF8_CALL_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_SET_BYTE_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (ambiguousTypedStatement) {
      return sequenceStatementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount
      );
    }

    return opcode;
  }
}
