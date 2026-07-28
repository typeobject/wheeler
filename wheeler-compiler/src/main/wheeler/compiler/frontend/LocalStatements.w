//! Resolves and sizes bounded local declarations and assertions.

module wheeler.compiler.local_statements;

import wheeler.compiler.conditionals;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.tokens;

classical class LocalStatements {
  private boolean declarationMatches(long opcode, boolean signed) {
    if (signed) {
      if (opcode == STATEMENT_LOCAL_LONG) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
        return true;
      }

      if (namedLongBinary(opcode)) {
        return true;
      }

      return namedLongPair(opcode);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED;
  }

  private long resolvePriorDeclaration(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long assertedName,
    boolean signed
  ) {
    if (previousCount < 0) {
      return -1;
    }

    if (MAX_MINIMAL_STATEMENTS < previousCount) {
      return -1;
    }

    long localBase = 0;
    long matchedLocal = -1;
    long matchCount = 0;
    long previous = 0;
    while (previous < previousCount) limit MAX_MINIMAL_STATEMENTS {
      long previousStart = previousStarts[previous];
      if (0 < previousStart) {
        long previousOpcode = statementOpcode(source, tokenStarts, tokenLengths, previousStart);
        if (declarationMatches(previousOpcode, signed)) {
          if (
            sameTokenText(source, tokenStarts, tokenLengths, previousStart + 1, assertedName)
          ) {
            matchedLocal = statementResultLocal(previousOpcode, localBase);
            matchCount += 1;
          }
        }

        localBase += statementLocalCount(previousOpcode);
      }

      previous += 1;
    }

    if (matchCount == 1) {
      return matchedLocal;
    }

    return -1;
  }

  /// Resolves named signed operations into opcodes carrying local indices.
  public long sequenceStatementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      long local = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      if (-1 < local) {
        return STATEMENT_ASSERT_LOCAL_LONG_BASE + local;
      }

      return -1;
    }

    if (opcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      long lessThanAssertionLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      if (-1 < lessThanAssertionLeft) {
        return STATEMENT_ASSERT_LONG_LT_BASE + lessThanAssertionLeft;
      }

      return -1;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      long pairAssertionSignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      long pairAssertionBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        false
      );
      if (-1 < pairAssertionSignedLeft) {
        if (pairAssertionBooleanLeft < 0) {
          return STATEMENT_ASSERT_LONG_PAIR_BASE + pairAssertionSignedLeft;
        }
      }

      if (-1 < pairAssertionBooleanLeft) {
        if (pairAssertionSignedLeft < 0) {
          return STATEMENT_ASSERT_BOOLEAN_PAIR_BASE + pairAssertionBooleanLeft;
        }
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      long sourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < sourceLocal) {
        return STATEMENT_LOCAL_LONG_COPY_BASE + sourceLocal;
      }

      return -1;
    }

    if (namedLongBinary(opcode)) {
      long binarySourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < binarySourceLocal) {
        long base = STATEMENT_LOCAL_LONG_ADD_BASE;
        if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
          base = STATEMENT_LOCAL_LONG_SUB_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_XOR_NAMED) {
          base = STATEMENT_LOCAL_LONG_XOR_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_MUL_NAMED) {
          base = STATEMENT_LOCAL_LONG_MUL_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_DIV_NAMED) {
          base = STATEMENT_LOCAL_LONG_DIV_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_MOD_NAMED) {
          base = STATEMENT_LOCAL_LONG_MOD_BASE;
        }

        return base + binarySourceLocal;
      }

      return -1;
    }

    if (namedLongPair(opcode)) {
      long pairSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < pairSourceLocal) {
        long pairBase = STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE;
        if (opcode == STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE;
        }

        return pairBase + pairSourceLocal;
      }

      return -1;
    }

    if (namedLiteralEqualityConditional(opcode)) {
      long comparisonSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      if (-1 < comparisonSourceLocal) {
        return namedLiteralEqualityConditionalBase(opcode) + comparisonSourceLocal;
      }

      return -1;
    }

    if (namedLocalConditional(opcode)) {
      long conditionToken = statementStart + 2;
      if (namedLocalConditionalNegated(opcode)) {
        conditionToken += 1;
      }

      long conditionalSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        conditionToken,
        false
      );
      if (-1 < conditionalSourceLocal) {
        return namedLocalConditionalBase(opcode) + conditionalSourceLocal;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      long equalityLiteralSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < equalityLiteralSource) {
        return STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE + equalityLiteralSource;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      long lessThanLiteralSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < lessThanLiteralSource) {
        return STATEMENT_LOCAL_LONG_LT_LITERAL_BASE + lessThanLiteralSource;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      long lessThanSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < lessThanSourceLocal) {
        return STATEMENT_LOCAL_LONG_LT_BASE + lessThanSourceLocal;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      long equalitySignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      long equalityBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        false
      );
      if (-1 < equalitySignedLeft) {
        if (equalityBooleanLeft < 0) {
          return STATEMENT_LOCAL_LONG_EQ_BASE + equalitySignedLeft;
        }
      }

      if (-1 < equalityBooleanLeft) {
        if (equalitySignedLeft < 0) {
          return STATEMENT_LOCAL_BOOLEAN_EQ_BASE + equalityBooleanLeft;
        }
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      long booleanSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        false
      );
      if (-1 < booleanSourceLocal) {
        return STATEMENT_LOCAL_BOOLEAN_COPY_BASE + booleanSourceLocal;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      long negatedSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 4,
        false
      );
      if (-1 < negatedSourceLocal) {
        return STATEMENT_LOCAL_BOOLEAN_NOT_BASE + negatedSourceLocal;
      }

      return -1;
    }

    return opcode;
  }

  /// Checks whether a resolved statement operand names a valid prior local.
  public boolean sequenceOperandValid(long opcode, long operand) {
    if (opcode < 0) {
      return false;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return -1 < operand;
    }

    if (resolvedLocalLongPair(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalEquality(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalLongLessThan(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalPairAssertion(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalConditionalAssignmentValue(opcode)) {
      return -1 < operand;
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      return -1 < operand;
    }

    if (namedGlobalUpdate(opcode)) {
      return -1 < operand;
    }

    return true;
  }

  /// Resolves one statement operand against a bounded prior-declaration table.
  public long sequenceStatementOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (namedGlobalUpdate(opcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
    }

    if (namedLocalConditionalValue(opcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementOperandToken(source, tokenStarts, tokenLengths, statementStart),
        true
      );
    }

    if (opcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 4,
        true
      );
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      long assertionSignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      long assertionSignedRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      if (-1 < assertionSignedLeft) {
        if (-1 < assertionSignedRight) {
          return assertionSignedRight;
        }
      }

      long assertionBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        false
      );
      long assertionBooleanRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        false
      );
      if (-1 < assertionBooleanLeft) {
        if (-1 < assertionBooleanRight) {
          return assertionBooleanRight;
        }
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      long operandSignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      long operandSignedRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 6,
        true
      );
      if (-1 < operandSignedLeft) {
        if (-1 < operandSignedRight) {
          return operandSignedRight;
        }
      }

      long operandBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        false
      );
      long operandBooleanRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 6,
        false
      );
      if (-1 < operandBooleanLeft) {
        if (-1 < operandBooleanRight) {
          return operandBooleanRight;
        }
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return 0;
    }

    if (namedLongPair(opcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        false
      );
    }

    return statementOperand(source, tokenStarts, tokenLengths, statementStart);
  }

  /// Decodes the canonical operand carried by one validated statement.
  public long statementOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    long operandToken = statementOperandToken(source, tokenStarts, tokenLengths, statementStart);
    boolean booleanLiteral = opcode == STATEMENT_LOCAL_BOOLEAN;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      booleanLiteral = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      booleanLiteral = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      booleanLiteral = true;
    }

    if (booleanLiteral) {
      long literal = tokenHash(source, tokenStarts, tokenLengths, operandToken);
      if (literal == TOKEN_TRUE) {
        return 1;
      }

      return 0;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return -1;
    }

    return parsedSignedNumber(source, tokenStarts, tokenLengths, operandToken);
  }

  /// Resolves the optional second scalar operand for one statement.
  public long sequenceStatementSecondaryOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (namedLiteralEqualityConditional(opcode)) {
      return parsedSignedNumber(source, tokenStarts, tokenLengths, statementStart + 5);
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      long leftWidth = 1;
      if (utf8Scalar(source, tokenStarts[statementStart + 2]) == PUNCTUATION_MINUS) {
        leftWidth = 2;
      }

      return parsedSignedNumber(
        source,
        tokenStarts,
        tokenLengths,
        statementStart + 2 + leftWidth + 2
      );
    }

    return 0;
  }

  /// Returns the operand-token offset for one bounded statement.
  public long statementOperandToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_ASSIGN) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return statementStart + 6;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      return statementStart + 5;
    }

    if (namedLiteralEqualityConditional(opcode)) {
      long comparisonWidth = 1;
      if (utf8Scalar(source, tokenStarts[statementStart + 5]) == PUNCTUATION_MINUS) {
        comparisonWidth = 2;
      }

      long comparisonOperandToken = statementStart + 10 + comparisonWidth;
      if (literalEqualityConditionalAssignment(opcode)) {
        comparisonOperandToken -= 1;
      }

      return comparisonOperandToken;
    }

    if (namedLocalConditional(opcode)) {
      long operandToken = statementStart + 8;
      if (namedLocalConditionalNegated(opcode)) {
        operandToken += 1;
      }

      if (namedLocalConditionalAssignment(opcode)) {
        operandToken -= 1;
      }

      return operandToken;
    }

    if (namedLongBinary(opcode)) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return statementStart + 4;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return statementStart + 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return statementStart + 2;
    }

    return statementStart + 3;
  }
}
