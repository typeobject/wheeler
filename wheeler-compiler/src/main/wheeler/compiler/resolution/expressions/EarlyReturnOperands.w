//! Resolves scalar operands carried by bounded early-return guards.

module wheeler.compiler.early_return_operands;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.loop_forms;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class EarlyReturnOperands {
  /// Carries one optional early-return operand resolution.
  public record EarlyReturnOperand(long value, boolean applies, boolean valid) {}

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

    if (resolvedEarlyBooleanReturn(opcode)) {
      long comparisonToken = statementStart + 5;
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

  /// Resolves the Boolean literal returned by one early guard.
  public EarlyReturnOperand resolveEarlyReturnSecondaryOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    long sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (resolvedEarlyHelperReturn(opcode)) {
      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED) {
        return new EarlyReturnOperand(1, true, true);
      }

      return new EarlyReturnOperand(0, true, true);
    }

    if (resolvedEarlyBooleanReturn(opcode)) {
      if (sourceOpcode == STATEMENT_IF_SIGNED_EQ_RETURN_TRUE_NAMED) {
        return new EarlyReturnOperand(1, true, true);
      }

      return new EarlyReturnOperand(0, true, true);
    }

    return new EarlyReturnOperand(0, false, false);
  }
}
