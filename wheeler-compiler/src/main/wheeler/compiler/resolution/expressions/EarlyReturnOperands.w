//! Resolves scalar operands carried by bounded early-return guards.

module wheeler.compiler.early_return_operands;

import wheeler.compiler.class_constants;
import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.loop_forms;
import wheeler.compiler.resolved_early_comparison_kinds;
import wheeler.compiler.resolved_early_result_kinds;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.tokens;

classical class EarlyReturnOperands {
  /// Carries one optional early-return operand resolution.
  public record EarlyReturnOperand(long value, boolean applies, boolean valid) {}

  private EarlyReturnOperand signedReturnOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long returnToken
  ) {
    if (loopOperandNamed(source, tokenStarts, returnToken)) {
      ConstantResolution constant = resolveClassConstant(
        source,
        tokenStarts,
        tokenLengths,
        returnToken,
        true
      );
      return new EarlyReturnOperand(constant.value, true, constant.valid);
    }

    return new EarlyReturnOperand(
      parsedSignedNumber(source, tokenStarts, tokenLengths, returnToken),
      true,
      true
    );
  }

  /// Resolves the primary scalar operand for one early-return guard.
  public EarlyReturnOperand resolveEarlyReturnOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    if (resolvedEarlyHelperReturn(opcode)) {
      return new EarlyReturnOperand(0, true, true);
    }

    if (resolvedEarlyComparisonReturn(opcode)) {
      long comparisonToken = statementStart + 5;
      if (resolvedEarlyLessReturn(opcode)) {
        comparisonToken = statementStart + 4;
      }

      if (loopOperandNamed(source, tokenStarts, comparisonToken)) {
        ConstantResolution comparisonConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          comparisonToken,
          true
        );
        return new EarlyReturnOperand(comparisonConstant.value, true, comparisonConstant.valid);
      }

      return new EarlyReturnOperand(
        parsedSignedNumber(source, tokenStarts, tokenLengths, comparisonToken),
        true,
        true
      );
    }

    return new EarlyReturnOperand(0, false, false);
  }

  /// Resolves the scalar literal returned by one early guard.
  public EarlyReturnOperand resolveEarlyReturnSecondaryOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    long sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (resolvedEarlySignedReturn(opcode)) {
      long returnToken = statementStart + 9;
      if (resolvedEarlyComparisonReturn(opcode)) {
        long comparisonToken = statementStart + 5;
        if (resolvedEarlyLessReturn(opcode)) {
          comparisonToken = statementStart + 4;
        }

        long comparisonWidth = 1;
        if (loopOperandNamed(source, tokenStarts, comparisonToken) == false) {
          if (utf8Scalar(source, tokenStarts[comparisonToken]) == PUNCTUATION_MINUS) {
            comparisonWidth = 2;
          }
        }

        returnToken = comparisonToken + comparisonWidth + 3;
        if (resolvedEarlyComputedReturn(opcode)) {
          returnToken += 2;
        }
      }

      return signedReturnOperand(source, tokenStarts, tokenLengths, returnToken);
    }

    if (resolvedEarlyHelperReturn(opcode)) {
      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED) {
        return new EarlyReturnOperand(1, true, true);
      }

      return new EarlyReturnOperand(0, true, true);
    }

    if (resolvedEarlyComparisonReturn(opcode)) {
      boolean returnsTrue = sourceOpcode == STATEMENT_IF_SIGNED_EQ_RETURN_TRUE_NAMED;
      if (sourceOpcode == STATEMENT_IF_SIGNED_LT_RETURN_TRUE_NAMED) {
        returnsTrue = true;
      }

      if (returnsTrue) {
        return new EarlyReturnOperand(1, true, true);
      }

      return new EarlyReturnOperand(0, true, true);
    }

    return new EarlyReturnOperand(0, false, false);
  }
}
