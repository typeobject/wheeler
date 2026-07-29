//! Resolves and sizes bounded local declarations and assertions.

module wheeler.compiler.local_statements;

import wheeler.compiler.class_constants;
import wheeler.compiler.conditionals;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.loop_forms;
import wheeler.compiler.scalar_opcodes;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class LocalStatements {
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
    if (opcode == STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED) {
      long whileTargetName = whileTargetToken(source, tokenStarts, statementStart);
      long whileTarget = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        whileTargetName,
        true
      );
      if (whileTarget < 0) {
        return -1;
      }

      long whileForm = 0;
      long whileConditionRight = whileConditionValueToken(source, tokenStarts, statementStart);
      if (whileReversed(source, tokenStarts, statementStart)) {
        whileForm += STATEMENT_LOCAL_WHILE_REVERSED_FORM;
      } else {
        if (loopOperandNamed(source, tokenStarts, whileConditionRight)) {
          long whileConditionLocal = resolvePriorDeclaration(
            source,
            tokenStarts,
            tokenLengths,
            previousStarts,
            previousCount,
            whileConditionRight,
            true
          );
          if (whileConditionLocal < 0) {
            return -1;
          }

          whileForm += STATEMENT_LOCAL_WHILE_CONDITION_NAMED;
        }
      }

      long whileLimit = whileLimitToken(source, tokenStarts, statementStart);
      if (loopOperandNamed(source, tokenStarts, whileLimit)) {
        long whileLimitLocal = resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          whileLimit,
          true
        );
        if (whileLimitLocal < 0) {
          return -1;
        }

        whileForm += STATEMENT_LOCAL_WHILE_LIMIT_NAMED;
      }

      long whileUpdateTarget = whileUpdateTargetToken(source, tokenStarts, statementStart);
      whileForm += whileUpdateForm(source, tokenStarts, whileUpdateTarget);
      return STATEMENT_LOCAL_WHILE_BASE + whileTarget * STATEMENT_LOCAL_WHILE_FORM_COUNT
        + whileForm;
    }

    if (localAssignmentSourceStatement(opcode)) {
      long assignmentSignedTarget = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        true
      );
      long assignmentBooleanTarget = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        false
      );
      boolean globalAssignmentTarget = tokenHash(source, tokenStarts, tokenLengths, 4)
        == TOKEN_STATE;
      if (globalAssignmentTarget) {
        globalAssignmentTarget = sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          6,
          statementStart
        );
      }

      boolean signedTarget = -1 < assignmentSignedTarget;
      boolean booleanTarget = -1 < assignmentBooleanTarget;
      if (signedTarget) {
        if (booleanTarget) {
          return -1;
        }

        if (globalAssignmentTarget) {
          return -1;
        }

        if (opcode == STATEMENT_ASSIGN) {
          return STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE + assignmentSignedTarget;
        }

        long assignmentSignedSource = resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          statementStart + 2,
          true
        );
        if (-1 < assignmentSignedSource) {
          return STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + assignmentSignedTarget;
        }

        return -1;
      }

      if (booleanTarget) {
        if (globalAssignmentTarget) {
          return -1;
        }

        long assignmentRightHash = tokenHash(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 2
        );
        if (booleanTokenHash(assignmentRightHash)) {
          return STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE + assignmentBooleanTarget;
        }

        long assignmentBooleanSource = resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          statementStart + 2,
          false
        );
        if (-1 < assignmentBooleanSource) {
          return STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE + assignmentBooleanTarget;
        }

        return -1;
      }

      if (globalAssignmentTarget) {
        return opcode;
      }

      return -1;
    }

    if (localUpdateSourceStatement(opcode)) {
      long updateTarget = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        true
      );
      boolean globalUpdateTarget = tokenHash(source, tokenStarts, tokenLengths, 4) == TOKEN_STATE;
      if (globalUpdateTarget) {
        globalUpdateTarget = sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          6,
          statementStart
        );
      }

      if (-1 < updateTarget) {
        if (globalUpdateTarget) {
          return -1;
        }

        long updateBase = STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
        if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
          updateBase = STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE;
        }

        if (opcode == STATEMENT_UPDATE_SUB) {
          updateBase = STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
        }

        if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
          updateBase = STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE;
        }

        if (opcode == STATEMENT_UPDATE_XOR) {
          updateBase = STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
        }

        if (opcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED) {
          updateBase = STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE;
        }

        return updateBase + updateTarget;
      }

      if (globalUpdateTarget) {
        return opcode;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED) {
      long callSignedArgument = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      long callBooleanArgument = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        false
      );
      if (-1 < callSignedArgument) {
        if (callBooleanArgument < 0) {
          return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
        }
      }

      if (-1 < callBooleanArgument) {
        if (callSignedArgument < 0) {
          return opcode;
        }
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      long pairCallSignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      long pairCallBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        false
      );
      long pairCallSignedRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 7,
        true
      );
      long pairCallBooleanRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 7,
        false
      );
      if (-1 < pairCallSignedLeft) {
        if (pairCallBooleanLeft < 0) {
          if (-1 < pairCallSignedRight) {
            if (pairCallBooleanRight < 0) {
              return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED;
            }
          }
        }
      }

      if (-1 < pairCallBooleanLeft) {
        if (pairCallSignedLeft < 0) {
          if (-1 < pairCallBooleanRight) {
            if (pairCallSignedRight < 0) {
              return opcode;
            }
          }
        }
      }

      return -1;
    }

    boolean ambiguousReturnPair = opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED;
    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
      ambiguousReturnPair = true;
    }

    if (ambiguousReturnPair) {
      long returnPairSignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        true
      );
      long returnPairBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        false
      );
      long returnPairSignedRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 4,
        true
      );
      long returnPairBooleanRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 4,
        false
      );
      if (-1 < returnPairSignedLeft) {
        if (returnPairBooleanLeft < 0) {
          if (-1 < returnPairSignedRight) {
            if (returnPairBooleanRight < 0) {
              if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
                return STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED;
              }

              return STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED;
            }
          }
        }
      }

      if (-1 < returnPairBooleanLeft) {
        if (returnPairSignedLeft < 0) {
          if (-1 < returnPairBooleanRight) {
            if (returnPairSignedRight < 0) {
              return opcode;
            }
          }
        }
      }

      return -1;
    }

    if (returnComparisonStatement(opcode)) {
      boolean signedComparison = returnComparisonSigned(opcode);
      long comparisonLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        signedComparison
      );
      if (comparisonLeft < 0) {
        return -1;
      }

      if (returnComparisonLocalRight(opcode)) {
        long comparisonRightToken = statementStart + 4;
        if (returnSignedLessThanStatement(opcode)) {
          comparisonRightToken -= 1;
        }

        long comparisonRight = resolvePriorDeclaration(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          comparisonRightToken,
          signedComparison
        );
        if (comparisonRight < 0) {
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

      return classConstantReturnOpcode(source, tokenStarts, tokenLengths, statementStart + 1);
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

      if (
        classConstantHasType(source, tokenStarts, tokenLengths, statementStart + 3, true)
      ) {
        return STATEMENT_LOCAL_LONG;
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

      if (
        classConstantHasType(source, tokenStarts, tokenLengths, statementStart + 3, false)
      ) {
        return STATEMENT_LOCAL_BOOLEAN;
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

      if (
        classConstantHasType(source, tokenStarts, tokenLengths, statementStart + 4, false)
      ) {
        return STATEMENT_LOCAL_BOOLEAN_NOT;
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

    if (resolvedLocalUpdateNamed(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalAssignmentNamed(opcode)) {
      return -1 < operand;
    }

    return true;
  }

}
