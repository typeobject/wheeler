//! Encodes local type windows for bounded non-helper statements.

module wheeler.compiler.statement_local_types;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_arguments;
import wheeler.compiler.call_forms;
import wheeler.compiler.conditionals;
import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.encoding;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.literal_comparison_operations;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_type_encoding;
import wheeler.compiler.named_comparison_kinds;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.owned_storage_forms;
import wheeler.compiler.owned_utf8_copy_loops;
import wheeler.compiler.resolved_boolean_literal_assertions;
import wheeler.compiler.resolved_boolean_literal_comparisons;
import wheeler.compiler.resolved_early_result_kinds;
import wheeler.compiler.resolved_less_than_assertions;
import wheeler.compiler.resolved_literal_comparison_kinds;
import wheeler.compiler.resolved_local_assignments;
import wheeler.compiler.resolved_local_conditional_kinds;
import wheeler.compiler.resolved_local_copy_kinds;
import wheeler.compiler.resolved_local_equality_kinds;
import wheeler.compiler.resolved_local_inequality_kinds;
import wheeler.compiler.resolved_local_less_than_kinds;
import wheeler.compiler.resolved_local_literal_comparisons;
import wheeler.compiler.resolved_local_loop_kinds;
import wheeler.compiler.resolved_local_pair_assertions;
import wheeler.compiler.resolved_local_returns;
import wheeler.compiler.resolved_local_updates;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.type_codes;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.wide_local_calls;

classical class StatementLocalTypes {
  private const long MAX_STATEMENT_LOCALS = 16;

  /// Writes canonical local type codes for one parsed statement.
  public long writeStatementLocalTypes(borrow mut bytes output, long cursor, long opcode) {
    long count = statementLocalCount(opcode);
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      cursor = writeLocalType(output, cursor, TYPE_REGION_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_BYTES);
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      return writeLocalType(output, cursor, TYPE_BYTES);
    }

    if (opcode == STATEMENT_DROP_MOVED_OWNED) {
      return cursor;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES);
      return writeLocalType(output, cursor, TYPE_UTF8);
    }

    if (opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8) {
      return writeLocalType(output, cursor, TYPE_UTF8);
    }

    if (opcode == STATEMENT_SET_WORD) {
      cursor = writeLocalType(output, cursor, TYPE_WORDS_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_SET_BYTE) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_SET_OWNED_BYTE) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_MAP_PUT) {
      cursor = writeLocalType(output, cursor, TYPE_LONG_MAP_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET) {
      cursor = writeLocalType(output, cursor, TYPE_LONG_MAP_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS) {
      cursor = writeLocalType(output, cursor, TYPE_LONG_MAP_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      cursor = writeLocalType(output, cursor, TYPE_BOOLEAN);
      return writeLocalType(output, cursor, TYPE_BOOLEAN);
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      cursor = writeLocalType(output, cursor, TYPE_LONG_MAP_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS) {
      cursor = writeLocalType(output, cursor, TYPE_LONG_MAP_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_BOOLEAN);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
      cursor = writeLocalType(output, cursor, TYPE_UTF8_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      cursor = writeLocalType(output, cursor, TYPE_UTF8_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      cursor = writeLocalType(output, cursor, TYPE_UTF8_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      cursor = writeLocalType(output, cursor, TYPE_UTF8_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES_BORROW);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES_BORROW);
      cursor = writeLocalType(output, cursor, TYPE_SIGNED);
      return writeLocalType(output, cursor, TYPE_SIGNED);
    }

    long returnCallArity = returnHelperCallArity(opcode);
    if (-1 < returnCallArity) {
      long argumentLocal = 0;
      while (argumentLocal < returnCallArity * 2) limit MAX_STATEMENT_LOCALS {
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
        argumentLocal += 1;
      }

      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedEarlyHelperForwardingReturn(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedEarlyHelperReturn(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      long helperResultType = TYPE_BOOLEAN;
      if (resolvedEarlySignedReturn(opcode)) {
        helperResultType = TYPE_SIGNED;
      }

      return writeUnsignedLittleEndian(output, cursor, helperResultType, 4);
    }

    if (resolvedEarlyComputedReturn(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
    }

    if (resolvedEarlyComparisonReturn(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      long comparisonResultType = TYPE_BOOLEAN;
      if (resolvedEarlySignedReturn(opcode)) {
        comparisonResultType = TYPE_SIGNED;
      }

      return writeUnsignedLittleEndian(output, cursor, comparisonResultType, 4);
    }

    if (ownedUtf8CopyLoop(opcode)) {
      cursor = writeLocalType(output, cursor, TYPE_BYTES);
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeBooleanLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeLocalType(output, cursor, TYPE_UTF8_BORROW);
      cursor = writeSignedLocalType(output, cursor);
      cursor = writeSignedLocalType(output, cursor);
      return writeSignedLocalType(output, cursor);
    }

    if (resolvedLocalWhile(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
    }

    if (resolvedLocalAssignment(opcode)) {
      long assignmentType = TYPE_SIGNED;
      if (resolvedLocalAssignmentBoolean(opcode)) {
        assignmentType = TYPE_BOOLEAN;
      }

      return writeUnsignedLittleEndian(output, cursor, assignmentType, 4);
    }

    if (resolvedLocalUpdate(opcode)) {
      return writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (oneArgumentBooleanSignedCall(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (oneArgumentBooleanCall(opcode)) {
      long callLocal = 0;
      while (callLocal < 4) limit MAX_STATEMENT_LOCALS {
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
        callLocal += 1;
      }

      return cursor;
    }

    if (twoArgumentBooleanSignedCall(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (twoArgumentBooleanCall(opcode)) {
      long pairCallLocal = 0;
      while (pairCallLocal < 6) limit MAX_STATEMENT_LOCALS {
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
        pairCallLocal += 1;
      }

      return cursor;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (returnComparisonStatement(opcode)) {
      long returnSourceType = TYPE_BOOLEAN;
      if (returnComparisonSigned(opcode)) {
        returnSourceType = TYPE_SIGNED;
      }

      cursor = writeUnsignedLittleEndian(output, cursor, returnSourceType, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, returnSourceType, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      if (returnInequalityStatement(opcode)) {
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      }

      return cursor;
    }

    if (resolvedLocalReturn(opcode)) {
      long resultType = TYPE_BOOLEAN;
      if (resolvedSignedLocalReturn(opcode)) {
        resultType = TYPE_SIGNED;
      }

      return writeUnsignedLittleEndian(output, cursor, resultType, 4);
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (opcode == STATEMENT_ASSERT_GLOBAL_CONSTANT) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedBooleanLiteralAssertion(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_SIGNED, 4);
      return writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
    }

    if (resolvedLiteralLessThanAssertion(opcode)) {
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

    if (resolvedLocalLiteralAssignmentConditional(opcode)) {
      long conditionType = TYPE_SIGNED;
      if (resolvedLocalLiteralAssignmentBoolean(opcode)) {
        conditionType = TYPE_BOOLEAN;
      }

      cursor = writeUnsignedLittleEndian(output, cursor, conditionType, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, conditionType, 4);
      cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
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
    if (resolvedLocalInequality(opcode)) {
      comparison = true;
    }

    if (resolvedLocalLongLessThan(opcode)) {
      comparison = true;
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      comparison = true;
    }

    if (resolvedBooleanLiteralComparison(opcode)) {
      comparison = true;
    }

    if (comparison) {
      long sourceType = TYPE_BOOLEAN;
      if (resolvedLocalEqualitySigned(opcode)) {
        sourceType = TYPE_SIGNED;
      }

      if (resolvedLocalInequalitySigned(opcode)) {
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
      boolean inequality = resolvedLocalInequality(opcode);
      if (resolvedLocalLiteralInequality(opcode)) {
        inequality = true;
      }

      if (resolvedBooleanLiteralInequality(opcode)) {
        inequality = true;
      }

      if (inequality) {
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
        cursor = writeUnsignedLittleEndian(output, cursor, TYPE_BOOLEAN, 4);
      }

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
    while (local < count) limit MAX_STATEMENT_LOCALS {
      cursor = writeUnsignedLittleEndian(output, cursor, typeCode, 4);
      local += 1;
    }

    return cursor;
  }
}
