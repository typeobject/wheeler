//! Resolves and sizes bounded local declarations and assertions.

module wheeler.compiler.local_statements;

import wheeler.compiler.conditionals;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.statement_forms;
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

      if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
        return true;
      }

      if (twoArgumentCallStatement(opcode)) {
        if (twoArgumentBooleanCall(opcode)) {} else {
          return true;
        }
      }

      if (namedLongBinary(opcode)) {
        return true;
      }

      return namedLongPair(opcode);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return true;
    }

    if (oneArgumentBooleanCall(opcode)) {
      return true;
    }

    if (twoArgumentBooleanCall(opcode)) {
      return true;
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

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED;
  }

  /// Resolves one source name through the bounded typed declaration history.
  public long resolvePriorDeclaration(
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

    if (MAX_HELPER_RESOLUTION_STARTS < previousCount) {
      return -1;
    }

    long localBase = 0;
    long matchedLocal = -1;
    long matchCount = 0;
    long previous = 0;
    while (previous < previousCount) limit MAX_HELPER_RESOLUTION_STARTS {
      long previousStart = previousStarts[previous];
      if (previousStart < 0) {
        long parameterToken = 0 - previousStart;
        boolean parameterSigned = true;
        if (BOOLEAN_PARAMETER_TOKEN_BIAS < parameterToken) {
          parameterToken -= BOOLEAN_PARAMETER_TOKEN_BIAS;
          parameterSigned = false;
        }

        if (signed == parameterSigned) {
          if (
            sameTokenText(source, tokenStarts, tokenLengths, parameterToken, assertedName)
          ) {
            matchedLocal = localBase;
            matchCount += 1;
          }
        }

        localBase += 1;
      } else {
        if (0 < previousStart) {
          long previousOpcode = statementOpcode(
            source,
            tokenStarts,
            tokenLengths,
            previousStart
          );
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
    if (returnBooleanComparisonStatement(opcode)) {
      long left = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        false
      );
      if (left < 0) {
        return -1;
      }

      boolean localComparison = opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED;
      if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
        localComparison = true;
      }

      if (localComparison) {
        long right = resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          statementStart + 4,
          false
        );
        if (right < 0) {
          return -1;
        }
      }

      return opcode;
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
          return STATEMENT_RETURN_SIGNED_LOCAL_BASE + signedReturn;
        }
      }

      if (-1 < booleanReturn) {
        if (signedReturn < 0) {
          return STATEMENT_RETURN_BOOLEAN_LOCAL_BASE + booleanReturn;
        }
      }

      return -1;
    }

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

        if (opcode == STATEMENT_LOCAL_LONG_AND_NAMED) {
          base = STATEMENT_LOCAL_LONG_AND_BASE;
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

        if (opcode == STATEMENT_LOCAL_LONG_AND_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_AND_LOCALS_BASE;
        }

        return pairBase + pairSourceLocal;
      }

      return -1;
    }

    if (namedLiteralComparisonConditional(opcode)) {
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
        return namedLiteralComparisonConditionalBase(opcode) + comparisonSourceLocal;
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

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      long inequalityLiteralSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < inequalityLiteralSource) {
        return STATEMENT_LOCAL_LONG_NE_LITERAL_BASE + inequalityLiteralSource;
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

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      long inequalitySignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      long inequalityBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        false
      );
      if (-1 < inequalitySignedLeft) {
        if (inequalityBooleanLeft < 0) {
          return STATEMENT_LOCAL_LONG_NE_BASE + inequalitySignedLeft;
        }
      }

      if (-1 < inequalityBooleanLeft) {
        if (inequalitySignedLeft < 0) {
          return STATEMENT_LOCAL_BOOLEAN_NE_BASE + inequalityBooleanLeft;
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

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return -1 < operand;
    }

    if (resolvedLocalLongPair(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalEquality(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalInequality(opcode)) {
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

}
