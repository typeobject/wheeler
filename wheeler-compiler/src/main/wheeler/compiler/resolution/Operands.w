//! Resolves bounded statement operands against typed prior declarations.

module wheeler.compiler.operands;

import wheeler.compiler.call_forms;
import wheeler.compiler.conditionals;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.local_statements;
import wheeler.compiler.loop_forms;
import wheeler.compiler.scalar_opcodes;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class Operands {
  private long operandResolutionOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    boolean ambiguousTypedStatement = opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (localUpdateSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (localAssignmentSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED) {
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

  /// Resolves one statement operand against a bounded prior-declaration table.
  public long sequenceStatementOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = operandResolutionOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStart,
      previousStarts,
      previousCount
    );
    if (resolvedLocalWhile(opcode)) {
      long whileConditionRight = statementStart + 4;
      if (resolvedLocalWhileConditionNamed(opcode)) {
        return resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          whileConditionRight,
          true
        );
      }

      return parsedSignedNumber(source, tokenStarts, tokenLengths, whileConditionRight);
    }

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

    if (resolvedLocalUpdateNamed(opcode)) {
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

    if (twoArgumentCallFirstNamed(opcode)) {
      boolean pairSignedArgument = true;
      if (twoArgumentBooleanCall(opcode)) {
        pairSignedArgument = false;
      }

      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        pairSignedArgument
      );
    }

    if (oneArgumentCallNamed(opcode)) {
      boolean signedArgument = true;
      if (oneArgumentBooleanCall(opcode)) {
        signedArgument = false;
      }

      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        signedArgument
      );
    }

    if (returnComparisonStatement(opcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        returnComparisonSigned(opcode)
      );
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
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

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      long signedReturn = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        true
      );
      long booleanReturn = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        false
      );
      if (-1 < signedReturn) {
        if (booleanReturn < 0) {
          return signedReturn;
        }
      }

      if (-1 < booleanReturn) {
        if (signedReturn < 0) {
          return booleanReturn;
        }
      }

      return -1;
    }

    if (resolvedLocalAssignmentNamed(opcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        resolvedLocalAssignmentBoolean(opcode) == false
      );
    }

    if (resolvedLocalAssignmentBoolean(opcode)) {
      long assignmentHash = tokenHash(source, tokenStarts, tokenLengths, statementStart + 2);
      if (assignmentHash == TOKEN_TRUE) {
        return 1;
      }

      return 0;
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

    boolean namedLocalComparison = opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      namedLocalComparison = true;
    }

    if (namedLocalComparison) {
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
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      booleanLiteral = true;
    }

    if (twoArgumentBooleanCall(opcode)) {
      booleanLiteral = true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      booleanLiteral = true;
    }

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

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      return 0;
    }

    if (returnLocalPairStatement(opcode)) {
      return 0;
    }

    return parsedSignedNumber(source, tokenStarts, tokenLengths, operandToken);
  }

  /// Resolves the optional second scalar operand for one statement.
  public long sequenceStatementSecondaryOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = operandResolutionOpcode(
      source,
      tokenStarts,
      tokenLengths,
      statementStart,
      previousStarts,
      previousCount
    );
    if (resolvedLocalWhile(opcode)) {
      long loopLimit = whileLimitToken(source, tokenStarts, statementStart);
      if (resolvedLocalWhileLimitNamed(opcode)) {
        return resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          loopLimit,
          true
        );
      }

      return parsedSignedNumber(source, tokenStarts, tokenLengths, loopLimit);
    }

    if (returnComparisonStatement(opcode)) {
      long returnComparisonRight = statementStart + 4;
      if (returnSignedLessThanStatement(opcode)) {
        returnComparisonRight -= 1;
      }

      if (returnComparisonLocalRight(opcode)) {
        return resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          returnComparisonRight,
          returnComparisonSigned(opcode)
        );
      }

      if (returnComparisonSigned(opcode)) {
        return parsedSignedNumber(source, tokenStarts, tokenLengths, returnComparisonRight);
      }

      long equalityLiteral = tokenHash(source, tokenStarts, tokenLengths, returnComparisonRight);
      if (equalityLiteral == TOKEN_TRUE) {
        return 1;
      }

      return 0;
    }

    if (twoArgumentCallStatement(opcode)) {
      long firstWidth = 1;
      if (utf8Scalar(source, tokenStarts[statementStart + 5]) == PUNCTUATION_MINUS) {
        firstWidth = 2;
      }

      long secondToken = statementStart + 6 + firstWidth;
      if (twoArgumentCallSecondNamed(opcode)) {
        boolean signedArgument = true;
        if (twoArgumentBooleanCall(opcode)) {
          signedArgument = false;
        }

        return resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          secondToken,
          signedArgument
        );
      }

      if (twoArgumentBooleanCall(opcode)) {
        long literal = tokenHash(source, tokenStarts, tokenLengths, secondToken);
        if (literal == TOKEN_TRUE) {
          return 1;
        }

        return 0;
      }

      return parsedSignedNumber(source, tokenStarts, tokenLengths, secondToken);
    }

    if (namedLiteralComparisonConditional(opcode)) {
      long comparisonToken = statementStart + 5;
      if (literalComparisonConditionalLessThan(opcode)) {
        comparisonToken -= 1;
      }

      return parsedSignedNumber(source, tokenStarts, tokenLengths, comparisonToken);
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

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return statementStart + 1;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return statementStart + 1;
    }

    if (oneArgumentCallStatement(opcode)) {
      return statementStart + 5;
    }

    if (twoArgumentCallStatement(opcode)) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      return statementStart + 1;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return statementStart + 3;
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

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      return statementStart + 6;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      return statementStart + 5;
    }

    if (namedLiteralComparisonConditional(opcode)) {
      long comparisonToken = statementStart + 5;
      if (literalComparisonConditionalLessThan(opcode)) {
        comparisonToken -= 1;
      }

      long comparisonWidth = 1;
      if (utf8Scalar(source, tokenStarts[comparisonToken]) == PUNCTUATION_MINUS) {
        comparisonWidth = 2;
      }

      long comparisonOperandToken = comparisonToken + comparisonWidth + 5;
      if (literalComparisonConditionalAssignment(opcode)) {
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
