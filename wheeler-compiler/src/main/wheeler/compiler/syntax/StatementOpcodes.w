//! Maps bounded source statement tokens to unresolved opcode identities.

module wheeler.compiler.statement_opcodes;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.identifier_starts;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;
import wheeler.compiler.void_call_source_kinds;

classical class StatementOpcodes {
  /// Maps one statement token to its bounded parser opcode.
  public long statementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long keyword = tokenHash(source, tokenStarts, tokenLengths, statementStart);
    if (keyword == TOKEN_SET) {
      return STATEMENT_SET_WORD_NAMED;
    }

    if (keyword == TOKEN_SET_BYTE) {
      return STATEMENT_SET_BYTE_NAMED;
    }

    if (keyword == TOKEN_PUT) {
      return STATEMENT_MAP_PUT_NAMED;
    }

    if (keyword == TOKEN_WHILE) {
      return STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED;
    }

    if (keyword == TOKEN_ASSERT) {
      long assertExpression = statementStart + 2;
      long assertHash = tokenHash(source, tokenStarts, tokenLengths, assertExpression);
      if (booleanTokenHash(assertHash)) {
        return STATEMENT_ASSERT_BOOLEAN;
      }

      long assertScalar = utf8Scalar(source, tokenStarts[assertExpression]);
      if (assertScalar == PUNCTUATION_BANG) {
        return STATEMENT_ASSERT_BOOLEAN_NOT;
      }

      if (identifierStart(assertScalar) == false) {
        return STATEMENT_ASSERT_LITERAL_EQ;
      }

      if (
        utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_CLOSE_PAREN
      ) {
        return STATEMENT_ASSERT_LOCAL_BOOLEAN;
      }

      if (0 < tokenLengths[COMPILER_GLOBAL_NAME_TOKEN]) {
        if (
          sameTokenText(
            source,
            tokenStarts,
            tokenLengths,
            COMPILER_GLOBAL_NAME_TOKEN,
            assertExpression
          )
        ) {
          return STATEMENT_ASSERT_EQ;
        }
      }

      if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_LESS_THAN) {
        return STATEMENT_ASSERT_LONG_LT_NAMED;
      }

      long assertedRight = utf8Scalar(source, tokenStarts[statementStart + 5]);
      if (identifierStart(assertedRight)) {
        return STATEMENT_ASSERT_LOCAL_PAIR_NAMED;
      }

      return STATEMENT_ASSERT_NAMED_LONG;
    }

    if (keyword == TOKEN_RETURN) {
      long returnedHash = tokenHash(source, tokenStarts, tokenLengths, statementStart + 1);
      if (booleanTokenHash(returnedHash)) {
        return STATEMENT_RETURN_BOOLEAN;
      }

      long returnedScalar = utf8Scalar(source, tokenStarts[statementStart + 1]);
      if (returnedScalar == PUNCTUATION_BANG) {
        return STATEMENT_RETURN_BOOLEAN_NOT_NAMED;
      }

      if (identifierStart(returnedScalar)) {
        long returnOperator = utf8Scalar(source, tokenStarts[statementStart + 2]);
        if (returnOperator == PUNCTUATION_OPEN_PAREN) {
          if (returnedHash == TOKEN_BUFFER_LENGTH) {
            return STATEMENT_RETURN_BUFFER_LENGTH_NAMED;
          }

          if (returnedHash == TOKEN_UTF8_SCALAR) {
            return STATEMENT_RETURN_UTF8_SCALAR_NAMED;
          }

          if (returnedHash == TOKEN_UTF8_WIDTH) {
            return STATEMENT_RETURN_UTF8_WIDTH_NAMED;
          }

          if (returnedHash == TOKEN_MAP_GET) {
            return STATEMENT_RETURN_MAP_GET_NAMED;
          }

          if (returnedHash == TOKEN_MAP_HAS) {
            return STATEMENT_RETURN_MAP_HAS_NAMED;
          }

          return STATEMENT_RETURN_HELPER_CALL_NAMED;
        }

        if (returnOperator == PUNCTUATION_OPEN_SQUARE) {
          return STATEMENT_RETURN_BUFFER_GET_NAMED;
        }

        boolean returnRightNamed = identifierStart(
          utf8Scalar(source, tokenStarts[statementStart + 3])
        );
        if (returnOperator == PUNCTUATION_ASSIGN) {
          long secondOperator = utf8Scalar(source, tokenStarts[statementStart + 3]);
          if (secondOperator == PUNCTUATION_ASSIGN) {
            long returnEqualityHash = tokenHash(
              source,
              tokenStarts,
              tokenLengths,
              statementStart + 4
            );
            if (booleanTokenHash(returnEqualityHash)) {
              return STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED;
            }

            long returnEqualityRight = utf8Scalar(source, tokenStarts[statementStart + 4]);
            if (identifierStart(returnEqualityRight)) {
              return STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED;
            }

            return STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED;
          }
        }

        if (returnOperator == PUNCTUATION_BANG) {
          long inequalityOperator = utf8Scalar(source, tokenStarts[statementStart + 3]);
          if (inequalityOperator == PUNCTUATION_ASSIGN) {
            long returnInequalityHash = tokenHash(
              source,
              tokenStarts,
              tokenLengths,
              statementStart + 4
            );
            if (booleanTokenHash(returnInequalityHash)) {
              return STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED;
            }

            long returnInequalityRight = utf8Scalar(source, tokenStarts[statementStart + 4]);
            if (identifierStart(returnInequalityRight)) {
              return STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED;
            }

            return STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED;
          }
        }

        if (returnOperator == PUNCTUATION_LESS_THAN) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_SIGNED_LT_LITERAL_NAMED;
        }

        if (returnOperator == PUNCTUATION_PLUS) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_LOCAL_ADD_NAMED;
        }

        if (returnOperator == PUNCTUATION_MINUS) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_LOCAL_SUB_NAMED;
        }

        if (returnOperator == PUNCTUATION_STAR) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_LOCAL_MUL_NAMED;
        }

        if (returnOperator == PUNCTUATION_SLASH) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_LOCAL_DIV_NAMED;
        }

        if (returnOperator == PUNCTUATION_PERCENT) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_LOCAL_MOD_NAMED;
        }

        if (returnOperator == PUNCTUATION_CARET) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_LOCAL_XOR_NAMED;
        }

        if (returnOperator == PUNCTUATION_AMPERSAND) {
          if (returnRightNamed) {
            return STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED;
          }

          return STATEMENT_RETURN_LOCAL_AND_NAMED;
        }

        return STATEMENT_RETURN_LOCAL_NAMED;
      }

      return STATEMENT_RETURN_LONG;
    }

    if (keyword == TOKEN_IF) {
      long conditionOperator = utf8Scalar(source, tokenStarts[statementStart + 3]);
      if (conditionOperator == PUNCTUATION_OPEN_PAREN) {
        long helperCallReturned = tokenHash(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 9
        );
        if (helperCallReturned == TOKEN_TRUE) {
          return STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED;
        }

        if (helperCallReturned == TOKEN_FALSE) {
          return STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED;
        }

        if (
          utf8Scalar(source, tokenStarts[statementStart + 10]) == PUNCTUATION_OPEN_PAREN
        ) {
          return STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED;
        }

        return STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED;
      }

      long comparisonLiteralToken = -1;
      boolean lessThanComparison = conditionOperator == PUNCTUATION_LESS_THAN;
      if (lessThanComparison) {
        comparisonLiteralToken = statementStart + 4;
      }

      if (conditionOperator == PUNCTUATION_ASSIGN) {
        long conditionSecondOperator = utf8Scalar(source, tokenStarts[statementStart + 4]);
        if (conditionSecondOperator == PUNCTUATION_ASSIGN) {
          comparisonLiteralToken = statementStart + 5;
        }
      }

      if (-1 < comparisonLiteralToken) {
        long comparisonWidth = 1;
        if (
          utf8Scalar(source, tokenStarts[comparisonLiteralToken]) == PUNCTUATION_MINUS
        ) {
          comparisonWidth = 2;
        }

        long bodyStart = comparisonLiteralToken + 2 + comparisonWidth;
        if (tokenHash(source, tokenStarts, tokenLengths, bodyStart) == TOKEN_RETURN) {
          long returned = tokenHash(source, tokenStarts, tokenLengths, bodyStart + 1);
          if (lessThanComparison) {
            if (returned == TOKEN_TRUE) {
              return STATEMENT_IF_SIGNED_LT_RETURN_TRUE_NAMED;
            }

            if (returned == TOKEN_FALSE) {
              return STATEMENT_IF_SIGNED_LT_RETURN_FALSE_NAMED;
            }

            long guardReturnOperator = utf8Scalar(source, tokenStarts[bodyStart + 2]);
            if (guardReturnOperator == PUNCTUATION_MINUS) {
              return STATEMENT_IF_SIGNED_LT_RETURN_SUB_NAMED;
            }

            if (guardReturnOperator == PUNCTUATION_PERCENT) {
              return STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_NAMED;
            }

            return STATEMENT_IF_SIGNED_LT_RETURN_LONG_NAMED;
          }

          if (returned == TOKEN_TRUE) {
            return STATEMENT_IF_SIGNED_EQ_RETURN_TRUE_NAMED;
          }

          if (returned == TOKEN_FALSE) {
            return STATEMENT_IF_SIGNED_EQ_RETURN_FALSE_NAMED;
          }

          return STATEMENT_IF_SIGNED_EQ_RETURN_LONG_NAMED;
        }

        long comparisonBodyOperator = utf8Scalar(
          source,
          tokenStarts[comparisonLiteralToken + 3 + comparisonWidth]
        );
        if (comparisonBodyOperator == PUNCTUATION_PLUS) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED;
        }

        if (comparisonBodyOperator == PUNCTUATION_MINUS) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED;
        }

        if (comparisonBodyOperator == PUNCTUATION_CARET) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED;
        }

        if (comparisonBodyOperator == PUNCTUATION_ASSIGN) {
          if (lessThanComparison) {
            return STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED;
          }

          return STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED;
        }

        return -1;
      }

      boolean negatedCondition = utf8Scalar(source, tokenStarts[statementStart + 2])
        == PUNCTUATION_BANG;
      long operatorToken = statementStart + 6;
      if (negatedCondition) {
        operatorToken += 1;
      }

      long conditionalOperator = utf8Scalar(source, tokenStarts[operatorToken]);
      long conditionalUpdateScalar = utf8Scalar(source, tokenStarts[operatorToken + 2]);
      boolean conditionalUpdateNamed = identifierStart(conditionalUpdateScalar);
      if (conditionalOperator == PUNCTUATION_PLUS) {
        if (negatedCondition) {
          if (conditionalUpdateNamed) {
            return STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED;
          }

          return STATEMENT_IF_NOT_LOCAL_ADD_NAMED;
        }

        if (conditionalUpdateNamed) {
          return STATEMENT_IF_LOCAL_ADD_VALUE_NAMED;
        }

        return STATEMENT_IF_LOCAL_ADD_NAMED;
      }

      if (conditionalOperator == PUNCTUATION_MINUS) {
        if (negatedCondition) {
          if (conditionalUpdateNamed) {
            return STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED;
          }

          return STATEMENT_IF_NOT_LOCAL_SUB_NAMED;
        }

        if (conditionalUpdateNamed) {
          return STATEMENT_IF_LOCAL_SUB_VALUE_NAMED;
        }

        return STATEMENT_IF_LOCAL_SUB_NAMED;
      }

      if (conditionalOperator == PUNCTUATION_CARET) {
        if (negatedCondition) {
          if (conditionalUpdateNamed) {
            return STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
          }

          return STATEMENT_IF_NOT_LOCAL_XOR_NAMED;
        }

        if (conditionalUpdateNamed) {
          return STATEMENT_IF_LOCAL_XOR_VALUE_NAMED;
        }

        return STATEMENT_IF_LOCAL_XOR_NAMED;
      }

      if (conditionalOperator == PUNCTUATION_ASSIGN) {
        long conditionalRightScalar = utf8Scalar(source, tokenStarts[operatorToken + 1]);
        if (identifierStart(conditionalRightScalar)) {
          if (negatedCondition) {
            return STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
          }

          return STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED;
        }

        if (negatedCondition) {
          return STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED;
        }

        return STATEMENT_IF_LOCAL_ASSIGN_NAMED;
      }

      return -1;
    }

    if (keyword == TOKEN_LONG) {
      long initializer = utf8Scalar(source, tokenStarts[statementStart + 3]);
      if (identifierStart(initializer)) {
        long initializerOperator = utf8Scalar(source, tokenStarts[statementStart + 4]);
        if (initializerOperator == PUNCTUATION_OPEN_SQUARE) {
          return STATEMENT_LOCAL_BUFFER_GET_NAMED;
        }

        if (initializerOperator == PUNCTUATION_OPEN_PAREN) {
          long initializerHash = tokenHash(
            source,
            tokenStarts,
            tokenLengths,
            statementStart + 3
          );
          if (initializerHash == TOKEN_BUFFER_LENGTH) {
            return STATEMENT_LOCAL_BUFFER_LENGTH_NAMED;
          }

          if (initializerHash == TOKEN_UTF8_SCALAR) {
            return STATEMENT_LOCAL_UTF8_SCALAR_NAMED;
          }

          if (initializerHash == TOKEN_UTF8_WIDTH) {
            return STATEMENT_LOCAL_UTF8_WIDTH_NAMED;
          }

          if (initializerHash == TOKEN_MAP_GET) {
            return STATEMENT_LOCAL_MAP_GET_NAMED;
          }

          long callArgument = utf8Scalar(source, tokenStarts[statementStart + 5]);
          if (callArgument == PUNCTUATION_CLOSE_PAREN) {
            return STATEMENT_LOCAL_CALL_NAMED;
          }

          boolean firstArgumentNamed = identifierStart(callArgument);
          long firstArgumentWidth = 1;
          if (callArgument == PUNCTUATION_MINUS) {
            firstArgumentWidth = 2;
          }

          long commaToken = statementStart + 5 + firstArgumentWidth;
          if (utf8Scalar(source, tokenStarts[commaToken]) == PUNCTUATION_COMMA) {
            boolean secondArgumentNamed = identifierStart(
              utf8Scalar(source, tokenStarts[commaToken + 1])
            );
            if (firstArgumentNamed) {
              if (secondArgumentNamed) {
                return STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED;
              }

              return STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED;
            }

            if (secondArgumentNamed) {
              return STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED;
            }

            return STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED;
          }

          if (firstArgumentNamed) {
            return STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED;
          }

          return STATEMENT_LOCAL_CALL_ARGUMENT_NAMED;
        }

        long rightScalar = utf8Scalar(source, tokenStarts[statementStart + 5]);
        boolean rightNamed = identifierStart(rightScalar);
        if (initializerOperator == PUNCTUATION_PLUS) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_ADD_NAMED;
        }

        if (initializerOperator == PUNCTUATION_MINUS) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_SUB_NAMED;
        }

        if (initializerOperator == PUNCTUATION_CARET) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_XOR_NAMED;
        }

        if (initializerOperator == PUNCTUATION_AMPERSAND) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_AND_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_AND_NAMED;
        }

        if (initializerOperator == PUNCTUATION_STAR) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_MUL_NAMED;
        }

        if (initializerOperator == PUNCTUATION_SLASH) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_DIV_NAMED;
        }

        if (initializerOperator == PUNCTUATION_PERCENT) {
          if (rightNamed) {
            return STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_LONG_MOD_NAMED;
        }

        return STATEMENT_LOCAL_LONG_NAMED;
      }

      return STATEMENT_LOCAL_LONG;
    }

    if (keyword == TOKEN_BOOLEAN) {
      if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_BANG) {
        long negated = tokenHash(source, tokenStarts, tokenLengths, statementStart + 4);
        if (booleanTokenHash(negated)) {
          return STATEMENT_LOCAL_BOOLEAN_NOT;
        }

        return STATEMENT_LOCAL_BOOLEAN_NOT_NAMED;
      }

      long booleanInitializer = tokenHash(source, tokenStarts, tokenLengths, statementStart + 3);
      if (booleanTokenHash(booleanInitializer)) {
        return STATEMENT_LOCAL_BOOLEAN;
      }

      long equality = utf8Scalar(source, tokenStarts[statementStart + 4]);
      if (equality == PUNCTUATION_OPEN_PAREN) {
        if (booleanInitializer == TOKEN_MAP_HAS) {
          return STATEMENT_LOCAL_MAP_HAS_NAMED;
        }

        long firstArgumentToken = statementStart + 5;
        long firstArgumentScalar = utf8Scalar(source, tokenStarts[firstArgumentToken]);
        if (firstArgumentScalar == PUNCTUATION_CLOSE_PAREN) {
          return STATEMENT_LOCAL_BOOLEAN_CALL_NAMED;
        }

        long firstArgumentHash = tokenHash(
          source,
          tokenStarts,
          tokenLengths,
          firstArgumentToken
        );
        boolean booleanFirstArgumentNamed = identifierStart(firstArgumentScalar);
        boolean firstArgumentBoolean = booleanTokenHash(firstArgumentHash);
        boolean firstArgumentSigned = false;
        long booleanCallFirstWidth = 1;
        if (firstArgumentBoolean) {
          booleanFirstArgumentNamed = false;
        } else {
          if (booleanFirstArgumentNamed) {} else {
            firstArgumentSigned = true;
            if (firstArgumentScalar == PUNCTUATION_MINUS) {
              booleanCallFirstWidth = 2;
            }
          }
        }

        long delimiterToken = firstArgumentToken + booleanCallFirstWidth;
        long delimiter = utf8Scalar(source, tokenStarts[delimiterToken]);
        if (delimiter == PUNCTUATION_CLOSE_PAREN) {
          if (firstArgumentSigned) {
            return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED;
          }

          if (booleanFirstArgumentNamed) {
            return STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
          }

          return STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED;
        }

        if (delimiter == PUNCTUATION_COMMA) {} else {
          return -1;
        }

        long secondArgumentToken = delimiterToken + 1;
        long secondArgumentScalar = utf8Scalar(source, tokenStarts[secondArgumentToken]);
        long secondArgumentHash = tokenHash(
          source,
          tokenStarts,
          tokenLengths,
          secondArgumentToken
        );
        boolean booleanSecondArgumentNamed = identifierStart(secondArgumentScalar);
        boolean secondArgumentBoolean = booleanTokenHash(secondArgumentHash);
        boolean secondArgumentSigned = false;
        if (secondArgumentBoolean) {
          booleanSecondArgumentNamed = false;
        } else {
          if (booleanSecondArgumentNamed) {} else {
            secondArgumentSigned = true;
          }
        }

        if (firstArgumentSigned) {
          if (secondArgumentSigned) {
            return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED;
          }

          if (booleanSecondArgumentNamed) {
            return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_SECOND_LOCAL_NAMED;
          }

          return -1;
        }

        if (secondArgumentSigned) {
          if (booleanFirstArgumentNamed) {
            return STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_FIRST_LOCAL_NAMED;
          }

          return -1;
        }

        if (booleanFirstArgumentNamed) {
          if (booleanSecondArgumentNamed) {
            return STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED;
          }

          return STATEMENT_LOCAL_BOOLEAN_CALL_TWO_FIRST_LOCAL_NAMED;
        }

        if (booleanSecondArgumentNamed) {
          return STATEMENT_LOCAL_BOOLEAN_CALL_TWO_SECOND_LOCAL_NAMED;
        }

        return STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED;
      }

      if (equality == PUNCTUATION_ASSIGN) {
        if (utf8Scalar(source, tokenStarts[statementStart + 5]) == PUNCTUATION_ASSIGN) {
          long equalityRight = utf8Scalar(source, tokenStarts[statementStart + 6]);
          if (identifierStart(equalityRight)) {
            return STATEMENT_LOCAL_BOOLEAN_EQ_NAMED;
          }

          return STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED;
        }
      }

      if (equality == PUNCTUATION_BANG) {
        if (utf8Scalar(source, tokenStarts[statementStart + 5]) == PUNCTUATION_ASSIGN) {
          long inequalityRight = utf8Scalar(source, tokenStarts[statementStart + 6]);
          if (identifierStart(inequalityRight)) {
            return STATEMENT_LOCAL_BOOLEAN_NE_NAMED;
          }

          return STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED;
        }
      }

      if (equality == PUNCTUATION_LESS_THAN) {
        long lessThanRight = utf8Scalar(source, tokenStarts[statementStart + 5]);
        if (identifierStart(lessThanRight)) {
          return STATEMENT_LOCAL_LONG_LT_NAMED;
        }

        return STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED;
      }

      return STATEMENT_LOCAL_BOOLEAN_NAMED;
    }

    long operator = utf8Scalar(source, tokenStarts[statementStart + 1]);
    if (operator == PUNCTUATION_OPEN_PAREN) {
      long firstArgument = utf8Scalar(source, tokenStarts[statementStart + 2]);
      if (firstArgument == PUNCTUATION_CLOSE_PAREN) {
        return STATEMENT_CALL_VOID_ZERO_NAMED;
      }

      long argumentEnd = utf8Scalar(source, tokenStarts[statementStart + 3]);
      if (argumentEnd == PUNCTUATION_CLOSE_PAREN) {
        return STATEMENT_CALL_VOID_ONE_NAMED;
      }

      if (argumentEnd == PUNCTUATION_COMMA) {
        long secondArgumentEnd = utf8Scalar(source, tokenStarts[statementStart + 5]);
        if (secondArgumentEnd == PUNCTUATION_CLOSE_PAREN) {
          return STATEMENT_CALL_VOID_TWO_NAMED;
        }

        if (secondArgumentEnd == PUNCTUATION_COMMA) {
          return STATEMENT_CALL_VOID_THREE_NAMED;
        }
      }

      return -1;
    }

    if (operator == PUNCTUATION_ASSIGN) {
      long assignedScalar = utf8Scalar(source, tokenStarts[statementStart + 2]);
      if (identifierStart(assignedScalar)) {
        return STATEMENT_ASSIGN_LOCAL_NAMED;
      }

      return STATEMENT_ASSIGN;
    }

    long updateScalar = utf8Scalar(source, tokenStarts[statementStart + 3]);
    boolean localUpdate = identifierStart(updateScalar);
    if (operator == PUNCTUATION_PLUS) {
      if (localUpdate) {
        return STATEMENT_UPDATE_ADD_LOCAL_NAMED;
      }

      return STATEMENT_UPDATE_ADD;
    }

    if (operator == PUNCTUATION_MINUS) {
      if (localUpdate) {
        return STATEMENT_UPDATE_SUB_LOCAL_NAMED;
      }

      return STATEMENT_UPDATE_SUB;
    }

    if (operator == PUNCTUATION_CARET) {
      if (localUpdate) {
        return STATEMENT_UPDATE_XOR_LOCAL_NAMED;
      }

      return STATEMENT_UPDATE_XOR;
    }

    return -1;
  }

}
