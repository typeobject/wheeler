//! Parses bounded local conditions in the bootstrap source profile.

module wheeler.compiler.conditionals;

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

    long operandWidth = signedNumberWidth(source, tokenKinds, tokenStarts, operandToken);
    if (operandWidth < 1) {
      return -1;
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, operandToken) == false) {
      return -1;
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

  /// Checks for a named signed literal-comparison condition.
  public boolean namedLiteralComparisonConditional(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED;
  }

  /// Checks for a resolved signed literal-comparison condition.
  public boolean resolvedLiteralComparisonConditional(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE + 256;
  }

  /// Checks whether a condition compares with signed less-than.
  public boolean literalComparisonConditionalLessThan(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE + 256;
  }

  /// Returns the signed source local carried by a comparison condition.
  public long resolvedLiteralComparisonConditionalSource(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE) {
      return opcode - STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE) {
      return opcode - STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE) {
      return opcode - STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE) {
      return opcode - STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE) {
      return opcode - STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE) {
      return opcode - STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE) {
      return opcode - STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE;
    }

    return opcode - STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE;
  }

  /// Checks whether a comparison condition guards subtraction.
  public boolean literalComparisonConditionalSubtract(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return true;
    }

    boolean equalitySubtract = STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE - 1 < opcode;
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE) {
      return equalitySubtract;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE;
  }

  /// Checks whether a comparison condition guards XOR.
  public boolean literalComparisonConditionalXor(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return true;
    }

    boolean equalityXor = STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE - 1 < opcode;
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE) {
      return equalityXor;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE;
  }

  /// Checks whether a comparison condition guards assignment.
  public boolean literalComparisonConditionalAssignment(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    boolean equalityAssignment = STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE - 1 < opcode;
    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE) {
      return equalityAssignment;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE + 256;
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

  /// Checks for a named one-arm Boolean condition guarding a global update.
  public boolean namedLocalConditional(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
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

  /// Checks whether a named local condition negates its Boolean source.
  public boolean namedLocalConditionalNegated(long opcode) {
    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
  }

  /// Checks whether a named local condition guards assignment.
  public boolean namedLocalConditionalAssignment(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
  }

  /// Checks whether a named local condition assigns another local.
  public boolean namedLocalConditionalAssignmentValue(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
  }

  /// Checks whether a named local condition reads a prior signed value.
  public boolean namedLocalConditionalValue(long opcode) {
    if (namedLocalConditionalAssignmentValue(opcode)) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
  }

  /// Checks whether an opcode carries a resolved local conditional source.
  public boolean resolvedLocalConditional(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ADD_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE + 256;
  }

  /// Checks whether a resolved local condition negates its Boolean source.
  public boolean resolvedLocalConditionalNegated(long opcode) {
    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE + 256;
  }

  /// Checks whether a resolved local condition guards assignment.
  public boolean resolvedLocalConditionalAssignment(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE + 256;
  }

  /// Checks whether a resolved condition assigns a prior signed local.
  public boolean resolvedLocalConditionalAssignmentValue(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE + 256;
  }

  /// Checks whether a resolved condition reads a prior signed value.
  public boolean resolvedLocalConditionalValue(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE + 256;
  }

  /// Checks whether a resolved local condition guards subtraction.
  public boolean resolvedLocalConditionalSubtract(long opcode) {
    if (STATEMENT_IF_LOCAL_SUB_BASE - 1 < opcode) {
      if (opcode < STATEMENT_IF_LOCAL_SUB_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_SUB_VALUE_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_SUB_VALUE_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE + 256;
  }

  /// Checks whether a resolved local condition guards XOR.
  public boolean resolvedLocalConditionalXor(long opcode) {
    if (STATEMENT_IF_LOCAL_XOR_BASE - 1 < opcode) {
      if (opcode < STATEMENT_IF_LOCAL_XOR_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_VALUE_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_VALUE_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE + 256;
  }

  /// Returns the condition local carried by a resolved conditional opcode.
  public long resolvedLocalConditionalSource(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_SUB_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ADD_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_BASE) {
      return opcode - STATEMENT_IF_LOCAL_SUB_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return opcode - STATEMENT_IF_LOCAL_XOR_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_ADD_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_SUB_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_XOR_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ASSIGN_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_ADD_VALUE_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_SUB_VALUE_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ADD_VALUE_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_VALUE_BASE) {
      return opcode - STATEMENT_IF_LOCAL_SUB_VALUE_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE) {
      return opcode - STATEMENT_IF_LOCAL_XOR_VALUE_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE;
    }

    return opcode - STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE;
  }

}
