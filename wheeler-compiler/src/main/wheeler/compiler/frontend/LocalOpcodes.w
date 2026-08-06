//! Classifies local-statement opcodes and their bounded register shapes.

module wheeler.compiler.local_opcodes;

import wheeler.compiler.borrowed_intrinsic_shapes;
import wheeler.compiler.call_forms;
import wheeler.compiler.conditionals;
import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.literal_comparison_operations;
import wheeler.compiler.named_boolean_return_kinds;
import wheeler.compiler.named_literal_comparison_kinds;
import wheeler.compiler.named_local_conditional_kinds;
import wheeler.compiler.named_long_operations;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.named_signed_return_kinds;
import wheeler.compiler.one_argument_calls;
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
import wheeler.compiler.resolved_long_operations;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.void_call_source_widths;
import wheeler.compiler.void_call_widths;

classical class LocalOpcodes {
  private const long EARLY_FORWARD_LOCAL_COUNT = 6;
  private const long EARLY_FORWARD_CODE_LENGTH = 232;
  private const long EARLY_FORWARD_INSTRUCTION_COUNT = 9;

  /// Returns the typed-local width required by one parsed statement.
  public long statementLocalCount(long opcode) {
    long voidCallLocals = voidCallLocalCount(opcode);
    if (-1 < voidCallLocals) {
      return voidCallLocals;
    }

    long intrinsicLocals = borrowedIntrinsicLocalCount(opcode);
    if (-1 < intrinsicLocals) {
      return intrinsicLocals;
    }

    if (resolvedEarlyHelperForwardingReturn(opcode)) {
      return EARLY_FORWARD_LOCAL_COUNT;
    }

    if (resolvedEarlyHelperReturn(opcode)) {
      return 4;
    }

    if (resolvedEarlyComputedReturn(opcode)) {
      return 6;
    }

    if (resolvedEarlyComparisonReturn(opcode)) {
      return 4;
    }

    if (resolvedLocalWhile(opcode)) {
      return 6;
    }

    if (resolvedLocalAssignment(opcode)) {
      return 1;
    }

    if (resolvedLocalUpdate(opcode)) {
      return 1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return 2;
    }

    if (oneArgumentCallStatement(opcode)) {
      return 4;
    }

    if (twoArgumentCallStatement(opcode)) {
      return 6;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return 3;
    }

    if (returnBooleanEqualityStatement(opcode)) {
      return 3;
    }

    if (returnSignedEqualityStatement(opcode)) {
      return 3;
    }

    if (returnSignedLessThanStatement(opcode)) {
      return 3;
    }

    if (returnBooleanInequalityStatement(opcode)) {
      return 5;
    }

    if (returnSignedInequalityStatement(opcode)) {
      return 5;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return 1;
    }

    if (returnHelperCallArity(opcode) == 0) {
      return 1;
    }

    if (returnHelperCallArity(opcode) == 4) {
      return 9;
    }

    if (returnHelperCallArity(opcode) == 3) {
      return 7;
    }

    if (returnHelperCallArity(opcode) == 2) {
      return 5;
    }

    if (resolvedReturnHelperCall(opcode)) {
      return 3;
    }

    if (resolvedLocalReturn(opcode)) {
      return 1;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      return 1;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return 3;
    }

    if (returnLocalPairStatement(opcode)) {
      return 3;
    }

    if (namedLiteralComparisonConditional(opcode)) {
      if (literalComparisonConditionalAssignment(opcode)) {
        return 4;
      }

      return 5;
    }

    if (resolvedLiteralComparisonConditional(opcode)) {
      if (literalComparisonConditionalAssignment(opcode)) {
        return 4;
      }

      return 5;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_GLOBAL_CONSTANT) {
      return 3;
    }

    if (resolvedBooleanLiteralAssertion(opcode)) {
      return 3;
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      if (resolvedLocalLiteralInequality(opcode)) {
        return 6;
      }

      return 4;
    }

    if (resolvedBooleanLiteralComparison(opcode)) {
      if (resolvedBooleanLiteralInequality(opcode)) {
        return 6;
      }

      return 4;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      return 4;
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      return 3;
    }

    if (resolvedLiteralLessThanAssertion(opcode)) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      return 3;
    }

    if (resolvedLocalPairAssertion(opcode)) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      return 3;
    }

    if (resolvedLocalConditional(opcode)) {
      if (resolvedLocalConditionalAssignment(opcode)) {
        if (resolvedLocalConditionalNegated(opcode)) {
          return 4;
        }

        return 2;
      }

      if (resolvedLocalConditionalNegated(opcode)) {
        return 5;
      }

      return 3;
    }

    if (namedLocalConditional(opcode)) {
      return 3;
    }

    if (resolvedLocalBooleanCopy(opcode)) {
      return 2;
    }

    if (resolvedLocalBooleanNot(opcode)) {
      return 4;
    }

    if (resolvedLocalEquality(opcode)) {
      return 4;
    }

    if (resolvedLocalInequality(opcode)) {
      return 6;
    }

    if (resolvedLocalLongLessThan(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return 4;
    }

    if (resolvedLocalLongAssertion(opcode)) {
      return 3;
    }

    if (resolvedLocalLongCopy(opcode)) {
      return 2;
    }

    if (resolvedLocalLongBinary(opcode)) {
      return 4;
    }

    if (resolvedLocalLongPair(opcode)) {
      return 4;
    }

    if (namedLongBinary(opcode)) {
      return 4;
    }

    if (namedLongPair(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      return 0;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return 4;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return 1;
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      return 1;
    }

    if (opcode == STATEMENT_UPDATE_ADD) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_XOR) {
      return 2;
    }

    if (namedGlobalUpdate(opcode)) {
      return 2;
    }

    return 0;
  }

  /// Returns the initialized result local for a declaration statement.
  public long statementResultLocal(long opcode, long localBase) {
    long intrinsicResult = borrowedIntrinsicResultOffset(opcode);
    if (-1 < intrinsicResult) {
      return localBase + intrinsicResult;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return localBase + 1;
    }

    if (oneArgumentCallStatement(opcode)) {
      return localBase + 3;
    }

    if (twoArgumentCallStatement(opcode)) {
      return localBase + 5;
    }

    if (namedLongBinary(opcode)) {
      return localBase + 3;
    }

    if (namedLongPair(opcode)) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      return localBase + 5;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      return localBase + 5;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      return localBase + 3;
    }

    return -1;
  }

  /// Returns the encoded byte width of one parsed statement.
  public long statementCodeLength(long opcode) {
    long voidCallLength = voidCallCodeLength(opcode);
    if (-1 < voidCallLength) {
      return voidCallLength;
    }

    long intrinsicLength = borrowedIntrinsicCodeLength(opcode);
    if (-1 < intrinsicLength) {
      return intrinsicLength;
    }

    if (resolvedEarlyHelperForwardingReturn(opcode)) {
      return EARLY_FORWARD_CODE_LENGTH;
    }

    if (resolvedEarlyHelperReturn(opcode)) {
      return 168;
    }

    if (resolvedEarlyComputedReturn(opcode)) {
      return 216;
    }

    if (resolvedEarlyComparisonReturn(opcode)) {
      return 160;
    }

    if (resolvedLocalWhile(opcode)) {
      return 248;
    }

    if (resolvedLocalAssignment(opcode)) {
      return 48;
    }

    if (resolvedLocalUpdate(opcode)) {
      return 56;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return 64;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return 64;
    }

    if (oneArgumentCallStatement(opcode)) {
      return 112;
    }

    if (twoArgumentCallStatement(opcode)) {
      return 160;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return 40;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return 96;
    }

    if (returnBooleanEqualityStatement(opcode)) {
      return 96;
    }

    if (returnSignedEqualityStatement(opcode)) {
      return 96;
    }

    if (returnSignedLessThanStatement(opcode)) {
      return 96;
    }

    if (returnBooleanInequalityStatement(opcode)) {
      return 152;
    }

    if (returnSignedInequalityStatement(opcode)) {
      return 152;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return 40;
    }

    if (returnHelperCallArity(opcode) == 0) {
      return 56;
    }

    if (returnHelperCallArity(opcode) == 4) {
      return 248;
    }

    if (returnHelperCallArity(opcode) == 3) {
      return 200;
    }

    if (returnHelperCallArity(opcode) == 2) {
      return 152;
    }

    if (resolvedReturnHelperCall(opcode)) {
      return 104;
    }

    if (resolvedLocalReturn(opcode)) {
      return 40;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      return 40;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return 96;
    }

    if (returnLocalPairStatement(opcode)) {
      return 96;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      return 96;
    }

    if (opcode == STATEMENT_ASSERT_GLOBAL_CONSTANT) {
      return 96;
    }

    if (resolvedBooleanLiteralAssertion(opcode)) {
      return 96;
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      if (resolvedLocalLiteralInequality(opcode)) {
        return 160;
      }

      return 104;
    }

    if (resolvedBooleanLiteralComparison(opcode)) {
      if (resolvedBooleanLiteralInequality(opcode)) {
        return 160;
      }

      return 104;
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      return 96;
    }

    if (resolvedLiteralLessThanAssertion(opcode)) {
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

    if (resolvedLocalInequality(opcode)) {
      return 160;
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
    long voidCallInstructions = voidCallInstructionCount(opcode);
    if (-1 < voidCallInstructions) {
      return voidCallInstructions;
    }

    long intrinsicInstructions = borrowedIntrinsicInstructionCount(opcode);
    if (-1 < intrinsicInstructions) {
      return intrinsicInstructions;
    }

    if (resolvedEarlyHelperForwardingReturn(opcode)) {
      return EARLY_FORWARD_INSTRUCTION_COUNT;
    }

    if (resolvedEarlyHelperReturn(opcode)) {
      return 7;
    }

    if (resolvedEarlyComputedReturn(opcode)) {
      return 9;
    }

    if (resolvedEarlyComparisonReturn(opcode)) {
      return 7;
    }

    if (resolvedLocalWhile(opcode)) {
      return 10;
    }

    if (resolvedLocalUpdate(opcode)) {
      return 2;
    }

    if (oneArgumentCallStatement(opcode)) {
      return 4;
    }

    if (twoArgumentCallStatement(opcode)) {
      return 6;
    }

    if (returnHelperCallArity(opcode) == 4) {
      return 10;
    }

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

    if (length == 56) {
      return 2;
    }

    if (length == 64) {
      return 2;
    }

    if (length == 112) {
      return 5;
    }

    if (length == 152) {
      return 6;
    }

    if (length == 160) {
      return 6;
    }

    if (length == 168) {
      return 7;
    }

    if (length == 200) {
      return 8;
    }

    if (length == 224) {
      return 9;
    }

    if (0 < length) {
      return 4;
    }

    return 0;
  }
}
