//! Resolves local-or-constant operands in bounded signed scalar expressions.

module wheeler.compiler.expression_operands;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.named_long_operations;
import wheeler.compiler.resolved_long_operations;
import wheeler.compiler.scalar_opcodes;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;

classical class ExpressionOperands {
  /// Carries one optional scalar expression operand without reserving a value.
  public record ExpressionOperand(long value, boolean applies, boolean valid) {}

  private ExpressionOperand resolved(long value) {
    return new ExpressionOperand(value, true, -1 < value);
  }

  private ExpressionOperand constant(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token,
    boolean signed
  ) {
    ConstantResolution value = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      token,
      signed
    );
    return new ExpressionOperand(value.value, true, value.valid);
  }

  /// Resolves the right operand of one signed arithmetic or comparison declaration.
  public ExpressionOperand resolveExpressionOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long sourceOpcode,
    long opcode,
    borrow mut words previousStarts,
    long previousCount
  ) {
    if (namedLongPair(sourceOpcode)) {
      long rightToken = statementStart + 5;
      if (resolvedLocalLongPair(opcode)) {
        return resolved(
          resolvePriorDeclaration(
            source,
            tokenStarts,
            tokenLengths,
            previousStarts,
            previousCount,
            rightToken,
            true
          )
        );
      }

      if (resolvedLocalLongBinary(opcode)) {
        return constant(source, tokenStarts, tokenLengths, rightToken, true);
      }

      return new ExpressionOperand(0, true, false);
    }

    if (sourceOpcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      long lessThanRight = statementStart + 5;
      if (resolvedLocalLiteralLessThan(opcode)) {
        return constant(source, tokenStarts, tokenLengths, lessThanRight, true);
      }

      if (resolvedLocalLongLessThan(opcode)) {
        return resolved(
          resolvePriorDeclaration(
            source,
            tokenStarts,
            tokenLengths,
            previousStarts,
            previousCount,
            lessThanRight,
            true
          )
        );
      }

      return new ExpressionOperand(0, true, false);
    }

    boolean comparison = sourceOpcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED;
    if (sourceOpcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      comparison = true;
    }

    if (comparison) {
      long comparisonRight = statementStart + 6;
      if (resolvedLocalLiteralComparison(opcode)) {
        return constant(source, tokenStarts, tokenLengths, comparisonRight, true);
      }

      if (resolvedBooleanLiteralComparison(opcode)) {
        return constant(source, tokenStarts, tokenLengths, comparisonRight, false);
      }

      boolean signed = resolvedLocalEqualitySigned(opcode);
      if (resolvedLocalInequalitySigned(opcode)) {
        signed = true;
      }

      return resolved(
        resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          comparisonRight,
          signed
        )
      );
    }

    return new ExpressionOperand(0, false, true);
  }
}
