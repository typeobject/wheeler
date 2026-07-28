//! Classifies bounded source statements and helper value forms.

module wheeler.compiler.statement_forms;

import wheeler.compiler.tokens;

classical class StatementForms {
  private boolean identifierStart(long scalar) {
    boolean accepted = scalar == 95;
    if (64 < scalar) {
      accepted = scalar < 91;
    }

    if (96 < scalar) {
      accepted = scalar < 123;
    }

    if (scalar == 95) {
      accepted = true;
    }

    return accepted;
  }

  /// Checks for one bounded helper value statement.
  public boolean helperValueStatement(long opcode) {
    if (STATEMENT_LOCAL_BOOLEAN_CALL_NAMED - 1 < opcode) {
      if (opcode < STATEMENT_RETURN_BOOLEAN + 1) {
        return true;
      }
    }

    if (oneArgumentCallStatement(opcode)) {
      return true;
    }

    if (twoArgumentCallStatement(opcode)) {
      return true;
    }

    if (returnLocalPairStatement(opcode)) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_CALL_NAMED) {
      return false;
    }

    return opcode < STATEMENT_RETURN_LOCAL_MOD_NAMED + 1;
  }

  /// Checks for a signed helper return with a literal right operand.
  public boolean returnLocalBinaryStatement(long opcode) {
    if (opcode < STATEMENT_RETURN_LOCAL_ADD_NAMED) {
      return false;
    }

    return opcode < STATEMENT_RETURN_LOCAL_MOD_NAMED + 1;
  }

  /// Checks for a signed or Boolean one-argument helper call.
  public boolean oneArgumentCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one helper call argument names a prior local.
  public boolean oneArgumentCallNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one helper call returns a Boolean.
  public boolean oneArgumentBooleanCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks for a signed two-argument helper call.
  public boolean twoArgumentCallStatement(long opcode) {
    if (opcode < STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED + 1;
  }

  /// Checks whether the first call argument names a prior local.
  public boolean twoArgumentCallFirstNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED;
  }

  /// Checks whether the second call argument names a prior local.
  public boolean twoArgumentCallSecondNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED;
  }

  /// Checks for a signed helper return using its parameter twice.
  public boolean returnLocalPairStatement(long opcode) {
    if (opcode < STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED) {
      return false;
    }

    return opcode < STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED + 1;
  }

  /// Checks the closed pair of Boolean literal token hashes.
  public boolean booleanTokenHash(long hash) {
    if (hash == TOKEN_TRUE) {
      return true;
    }

    return hash == TOKEN_FALSE;
  }

  /// Maps one statement token to its bounded parser opcode.
  public long statementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long keyword = tokenHash(source, tokenStarts, tokenLengths, statementStart);
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

      if (tokenHash(source, tokenStarts, tokenLengths, 5) == TOKEN_LONG) {
        if (sameTokenText(source, tokenStarts, tokenLengths, 6, assertExpression)) {
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
      if (identifierStart(returnedScalar)) {
        long returnOperator = utf8Scalar(source, tokenStarts[statementStart + 2]);
        boolean returnRightNamed = identifierStart(
          utf8Scalar(source, tokenStarts[statementStart + 3])
        );
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

        return STATEMENT_RETURN_LOCAL_NAMED;
      }

      return STATEMENT_RETURN_LONG;
    }

    if (keyword == TOKEN_IF) {
      long conditionOperator = utf8Scalar(source, tokenStarts[statementStart + 3]);
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
        if (initializerOperator == PUNCTUATION_OPEN_PAREN) {
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
        long booleanCallArgument = utf8Scalar(source, tokenStarts[statementStart + 5]);
        if (booleanCallArgument == PUNCTUATION_CLOSE_PAREN) {
          return STATEMENT_LOCAL_BOOLEAN_CALL_NAMED;
        }

        long booleanArgumentHash = tokenHash(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 5
        );
        if (booleanTokenHash(booleanArgumentHash)) {
          return STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED;
        }

        if (identifierStart(booleanCallArgument)) {
          return STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
        }

        return -1;
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
