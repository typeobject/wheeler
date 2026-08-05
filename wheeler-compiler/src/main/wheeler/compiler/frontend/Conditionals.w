//! Parses bounded local conditions in the bootstrap source profile.

module wheeler.compiler.conditionals;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.named_literal_comparison_kinds;
import wheeler.compiler.named_literal_comparison_operations;
import wheeler.compiler.named_local_conditional_kinds;
import wheeler.compiler.named_local_conditional_values;
import wheeler.compiler.resolved_literal_comparison_kinds;
import wheeler.compiler.resolved_literal_comparison_operations;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class Conditionals {
  /// Returns the token width of one signed literal-comparison condition.
  public long literalComparisonConditionalWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (namedLiteralComparisonConditional(statementKind) == false) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      ) == false
    ) {
      return -1;
    }

    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    long comparisonStart = statementStart + 5;
    if (literalComparisonConditionalLessThan(statementKind)) {
      comparisonStart = statementStart + 4;
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 3,
          PUNCTUATION_LESS_THAN
        ) == false
      ) {
        return -1;
      }
    } else {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 4, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }
    }

    long comparisonWidth = 1;
    if (tokenKinds[comparisonStart] == 1) {} else {
      comparisonWidth = signedNumberWidth(source, tokenKinds, tokenStarts, comparisonStart);
      if (comparisonWidth < 1) {
        return -1;
      }

      if (
        signedNumberValid(source, tokenStarts, tokenLengths, comparisonStart) == false
      ) {
        return -1;
      }
    }

    long closeCondition = comparisonStart + comparisonWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeCondition, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        closeCondition + 1,
        PUNCTUATION_OPEN_BRACE
      ) == false
    ) {
      return -1;
    }

    if (
      sameTokenText(
        source,
        tokenStarts,
        tokenLengths,
        COMPILER_GLOBAL_NAME_TOKEN,
        closeCondition + 2
      ) == false
    ) {
      return -1;
    }

    long operatorToken = closeCondition + 3;
    long expectedOperator = PUNCTUATION_PLUS;
    if (literalComparisonConditionalSubtract(statementKind)) {
      expectedOperator = PUNCTUATION_MINUS;
    }

    if (literalComparisonConditionalXor(statementKind)) {
      expectedOperator = PUNCTUATION_CARET;
    }

    if (literalComparisonConditionalAssignment(statementKind)) {
      expectedOperator = PUNCTUATION_ASSIGN;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, operatorToken, expectedOperator) == false
    ) {
      return -1;
    }

    long operandToken = operatorToken + 1;
    if (literalComparisonConditionalAssignment(statementKind) == false) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, operandToken, PUNCTUATION_ASSIGN) == false
      ) {
        return -1;
      }

      operandToken += 1;
    }

    long operandWidth = 1;
    if (tokenKinds[operandToken] == 1) {} else {
      operandWidth = signedNumberWidth(source, tokenKinds, tokenStarts, operandToken);
      if (operandWidth < 1) {
        return -1;
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, operandToken) == false) {
        return -1;
      }
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        operandToken + operandWidth,
        PUNCTUATION_SEMICOLON
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        operandToken + operandWidth + 1,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {
      return operandToken + operandWidth + 2 - statementStart;
    }

    return -1;
  }

  /// Returns the token width of one supported local condition.
  public long conditionalStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (namedLocalConditional(statementKind) == false) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      ) == false
    ) {
      return -1;
    }

    long conditionToken = statementStart + 2;
    long bodyShift = 0;
    if (namedLocalConditionalNegated(statementKind)) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, conditionToken, PUNCTUATION_BANG) == false
      ) {
        return -1;
      }

      conditionToken += 1;
      bodyShift = 1;
    }

    if (tokenKinds[conditionToken] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 3 + bodyShift,
        PUNCTUATION_CLOSE_PAREN
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 4 + bodyShift,
        PUNCTUATION_OPEN_BRACE
      ) == false
    ) {
      return -1;
    }

    if (
      sameTokenText(
        source,
        tokenStarts,
        tokenLengths,
        COMPILER_GLOBAL_NAME_TOKEN,
        statementStart + 5 + bodyShift
      ) == false
    ) {
      return -1;
    }

    long operatorToken = statementStart + 7 + bodyShift;
    long operandToken = statementStart + 8 + bodyShift;
    if (namedLocalConditionalAssignment(statementKind)) {
      operatorToken -= 1;
      operandToken -= 1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, operatorToken, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long operandWidth = signedNumberWidth(source, tokenKinds, tokenStarts, operandToken);
    if (namedLocalConditionalValue(statementKind)) {
      if (tokenKinds[operandToken] == 1) {
        operandWidth = 1;
      }
    }

    if (operandWidth < 1) {
      return -1;
    }

    if (namedLocalConditionalValue(statementKind) == false) {
      if (signedNumberValid(source, tokenStarts, tokenLengths, operandToken) == false) {
        return -1;
      }
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        operandToken + operandWidth,
        PUNCTUATION_SEMICOLON
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        operandToken + operandWidth + 1,
        PUNCTUATION_CLOSE_BRACE
      ) == false
    ) {
      return -1;
    }

    return operandToken - statementStart + operandWidth + 2;
  }

  /// Returns the global-update operand token in one signed comparison condition.
  public long literalComparisonConditionalOperandToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long comparisonToken = statementStart + 5;
    if (literalComparisonConditionalLessThan(opcode)) {
      comparisonToken -= 1;
    }

    long comparisonWidth = 1;
    if (utf8Scalar(source, tokenStarts[comparisonToken]) == PUNCTUATION_MINUS) {
      comparisonWidth = 2;
    }

    long operandToken = comparisonToken + comparisonWidth + 5;
    if (literalComparisonConditionalAssignment(opcode)) {
      operandToken -= 1;
    }

    return operandToken;
  }

  /// Checks whether a condition compares with signed less-than.
  public boolean literalComparisonConditionalLessThan(long opcode) {
    if (namedLiteralComparisonConditionalLessThan(opcode)) {
      return true;
    }

    return resolvedLiteralComparisonConditionalLessThan(opcode);
  }

  /// Checks whether a comparison condition guards subtraction.
  public boolean literalComparisonConditionalSubtract(long opcode) {
    if (namedLiteralComparisonConditionalSubtract(opcode)) {
      return true;
    }

    return resolvedLiteralComparisonConditionalSubtract(opcode);
  }

  /// Checks whether a comparison condition guards XOR.
  public boolean literalComparisonConditionalXor(long opcode) {
    if (namedLiteralComparisonConditionalXor(opcode)) {
      return true;
    }

    return resolvedLiteralComparisonConditionalXor(opcode);
  }

  /// Checks whether a comparison condition guards assignment.
  public boolean literalComparisonConditionalAssignment(long opcode) {
    if (namedLiteralComparisonConditionalAssignment(opcode)) {
      return true;
    }

    return resolvedLiteralComparisonConditionalAssignment(opcode);
  }

  /// Returns the resolved base for one signed comparison condition.
  public long namedLiteralComparisonConditionalBase(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      return STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE;
    }

    return STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE;
  }

  /// Returns the resolved opcode base for one named local condition.
  public long namedLocalConditionalBase(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ADD_NAMED) {
      return STATEMENT_IF_LOCAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_NAMED) {
      return STATEMENT_IF_LOCAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_NAMED) {
      return STATEMENT_IF_LOCAL_XOR_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_XOR_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return STATEMENT_IF_LOCAL_ASSIGN_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_ADD_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_ADD_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_SUB_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_XOR_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE;
    }

    return STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE;
  }
}
