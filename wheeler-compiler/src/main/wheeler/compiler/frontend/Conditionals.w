//! Parses bounded local conditions in the bootstrap source profile.

module wheeler.compiler.conditionals;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.literal_comparison_operations;
import wheeler.compiler.named_literal_comparison_kinds;
import wheeler.compiler.named_local_conditional_kinds;
import wheeler.compiler.named_local_conditional_values;
import wheeler.compiler.resolved_literal_comparison_kinds;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class Conditionals {
  /// Names local equality guards assigning Boolean literals to prior locals.
  public const long STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_LOCAL_NAMED = 935;
  /// Names local less-than guards assigning Boolean literals to prior locals.
  public const long STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_LOCAL_NAMED = 936;
  /// Names reversed less-than guards assigning Boolean literals to prior locals.
  public const long STATEMENT_IF_LITERAL_LT_LOCAL_ASSIGN_LOCAL_NAMED = 937;
  /// Starts resolved literal guards assigning Boolean literals to prior locals.
  public const long STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE = 32256;

  private const long LOCAL_LITERAL_ASSIGNMENT_FORM_COUNT = 16;
  private const long LOCAL_LITERAL_ASSIGNMENT_OPCODE_COUNT = 4096;

  /// Checks whether one source guard assigns a Boolean literal to a prior local.
  public boolean localLiteralAssignmentConditional(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LITERAL_LT_LOCAL_ASSIGN_LOCAL_NAMED;
  }

  /// Checks whether one source guard orders a local and a signed literal.
  public boolean localLiteralAssignmentLessThan(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LITERAL_LT_LOCAL_ASSIGN_LOCAL_NAMED;
  }

  /// Checks whether one source guard places its signed literal before the local.
  public boolean localLiteralAssignmentReversed(long opcode) {
    return opcode == STATEMENT_IF_LITERAL_LT_LOCAL_ASSIGN_LOCAL_NAMED;
  }

  /// Returns the condition-local token for one local-literal assignment guard.
  public long localLiteralAssignmentConditionToken(long statementStart, long opcode) {
    if (localLiteralAssignmentReversed(opcode)) {
      return statementStart + 4;
    }

    return statementStart + 2;
  }

  /// Returns the comparison-literal token for one local assignment guard.
  public long localLiteralAssignmentComparisonToken(long statementStart, long opcode) {
    if (localLiteralAssignmentReversed(opcode)) {
      return statementStart + 2;
    }

    if (localLiteralAssignmentLessThan(opcode)) {
      return statementStart + 4;
    }

    return statementStart + 5;
  }

  /// Returns the assignment-target token for one local assignment guard.
  public long localLiteralAssignmentTargetToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long literalToken = localLiteralAssignmentComparisonToken(statementStart, opcode);
    long literalWidth = 1;
    if (utf8Scalar(source, tokenStarts[literalToken]) == PUNCTUATION_MINUS) {
      literalWidth = 2;
    }

    long targetToken = literalToken + literalWidth + 2;
    if (localLiteralAssignmentReversed(opcode)) {
      targetToken += 2;
    }

    return targetToken;
  }

  /// Checks whether the condition literal is Boolean.
  public boolean localLiteralAssignmentBooleanCondition(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    long literalToken = localLiteralAssignmentComparisonToken(statementStart, opcode);
    long literal = tokenHash(source, tokenStarts, tokenLengths, literalToken);
    if (literal == TOKEN_TRUE) {
      return true;
    }

    return literal == TOKEN_FALSE;
  }

  /// Returns the exact token width of one local-literal assignment guard.
  public long localLiteralAssignmentConditionalWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    if (localLiteralAssignmentConditional(opcode) == false) {
      return -1;
    }

    long conditionToken = localLiteralAssignmentConditionToken(statementStart, opcode);
    long literalToken = localLiteralAssignmentComparisonToken(statementStart, opcode);
    if (tokenKinds[conditionToken] == 1) {} else {
      return -1;
    }

    long literalWidth = 1;
    long literal = tokenHash(source, tokenStarts, tokenLengths, literalToken);
    boolean booleanLiteral = literal == TOKEN_TRUE;
    if (literal == TOKEN_FALSE) {
      booleanLiteral = true;
    }

    if (booleanLiteral == false) {
      literalWidth = signedNumberWidth(source, tokenKinds, tokenStarts, literalToken);
      if (literalWidth < 1) {
        return -1;
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, literalToken) == false) {
        return -1;
      }
    }

    if (localLiteralAssignmentLessThan(opcode)) {
      if (booleanLiteral) {
        return -1;
      }

      long lessThanToken = statementStart + 3;
      if (localLiteralAssignmentReversed(opcode)) {
        lessThanToken = literalToken + literalWidth;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, lessThanToken, PUNCTUATION_LESS_THAN)
          == false
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

    long targetToken = localLiteralAssignmentTargetToken(
      source,
      tokenStarts,
      statementStart,
      opcode
    );
    if (tokenKinds[targetToken] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, targetToken - 2, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, targetToken - 1, PUNCTUATION_OPEN_BRACE)
        == false
    ) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, targetToken + 1, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long assigned = tokenHash(source, tokenStarts, tokenLengths, targetToken + 2);
    if (assigned == TOKEN_TRUE) {} else {
      if (assigned == TOKEN_FALSE) {} else {
        return -1;
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, targetToken + 3, PUNCTUATION_SEMICOLON)
        == false
    ) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, targetToken + 4, PUNCTUATION_CLOSE_BRACE)
    ) {
      return targetToken + 5 - statementStart;
    }

    return -1;
  }

  /// Resolves one local assignment guard into a source-local opcode.
  public long resolvedLocalLiteralAssignmentOpcode(
    long sourceLocal,
    boolean booleanCondition,
    boolean lessThan,
    boolean reversed,
    boolean assignedValue
  ) {
    long form = 0;
    if (assignedValue) {
      form += 1;
    }

    if (booleanCondition) {
      form += 2;
    }

    if (lessThan) {
      form += 4;
    }

    if (reversed) {
      form += 8;
    }

    return STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE + sourceLocal
      * LOCAL_LITERAL_ASSIGNMENT_FORM_COUNT + form;
  }

  /// Checks whether one opcode is a resolved local assignment guard.
  public boolean resolvedLocalLiteralAssignmentConditional(long opcode) {
    if (opcode < STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE + LOCAL_LITERAL_ASSIGNMENT_OPCODE_COUNT;
  }

  /// Returns the condition source local encoded in one resolved guard.
  public long resolvedLocalLiteralAssignmentSource(long opcode) {
    return(opcode - STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE) / LOCAL_LITERAL_ASSIGNMENT_FORM_COUNT;
  }

  /// Checks whether one resolved assignment guard compares Boolean values.
  public boolean resolvedLocalLiteralAssignmentBoolean(long opcode) {
    long form = (opcode - STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE)
      % LOCAL_LITERAL_ASSIGNMENT_FORM_COUNT;
    return 1 < form % 4;
  }

  /// Checks whether one resolved assignment guard is a less-than comparison.
  public boolean resolvedLocalLiteralAssignmentLessThan(long opcode) {
    long form = (opcode - STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE)
      % LOCAL_LITERAL_ASSIGNMENT_FORM_COUNT;
    return 3 < form % 8;
  }

  /// Checks whether one resolved assignment guard reverses less-than operands.
  public boolean resolvedLocalLiteralAssignmentReversed(long opcode) {
    long form = (opcode - STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE)
      % LOCAL_LITERAL_ASSIGNMENT_FORM_COUNT;
    return 7 < form;
  }

  /// Returns the Boolean literal assigned by one resolved guard.
  public long resolvedLocalLiteralAssignmentValue(long opcode) {
    return(opcode - STATEMENT_IF_LITERAL_ASSIGN_LOCAL_BASE) % 2;
  }

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

}
