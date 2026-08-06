//! Resolves bounded statement operands against typed prior declarations.

module wheeler.compiler.operands;

import wheeler.compiler.assertion_resolution;
import wheeler.compiler.boolean_tokens;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.class_constants;
import wheeler.compiler.conditionals;
import wheeler.compiler.early_return_kinds;
import wheeler.compiler.early_return_operands;
import wheeler.compiler.expression_operands;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.local_statements;
import wheeler.compiler.loop_forms;
import wheeler.compiler.loop_kinds;
import wheeler.compiler.mutation_resolution;
import wheeler.compiler.named_comparison_kinds;
import wheeler.compiler.named_literal_comparison_kinds;
import wheeler.compiler.named_local_assignment_kinds;
import wheeler.compiler.named_local_conditional_kinds;
import wheeler.compiler.named_local_conditional_values;
import wheeler.compiler.named_local_update_kinds;
import wheeler.compiler.named_long_operations;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.named_return_comparison_operands;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.resolved_local_assignments;
import wheeler.compiler.resolved_local_loop_forms;
import wheeler.compiler.resolved_local_loop_kinds;
import wheeler.compiler.resolved_local_loop_operands;
import wheeler.compiler.resolved_local_updates;
import wheeler.compiler.return_expressions;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.two_argument_call_kinds;

classical class Operands {
  /// Selects the typed opcode used for operand resolution.
  public long operandResolutionOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    boolean ambiguousTypedStatement = oneArgumentCallNamed(opcode);
    if (earlyReturnStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (twoArgumentCallFirstNamed(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (twoArgumentCallSecondNamed(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (returnComparisonLocalRight(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (returnLocalPairStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (localUpdateSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (localAssignmentSourceStatement(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (namedLongPair(opcode)) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      ambiguousTypedStatement = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
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
    long sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (sourceOpcode == STATEMENT_SET_WORD_NAMED) {
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

    if (sourceOpcode == STATEMENT_SET_BYTE_NAMED) {
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

    if (sourceOpcode == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
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

    if (sourceOpcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
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

    if (sourceOpcode == STATEMENT_LOCAL_UTF8_SCALAR_NAMED) {
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

    if (sourceOpcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
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

    if (sourceOpcode == STATEMENT_RETURN_BUFFER_LENGTH_NAMED) {
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

    EarlyReturnOperand earlyReturn = resolveEarlyReturnOperand(
      source,
      tokenStarts,
      tokenLengths,
      statementStart,
      opcode
    );
    if (earlyReturn.applies) {
      if (earlyReturn.valid) {
        return earlyReturn.value;
      }

      return -1;
    }

    if (-1 < opcode) {
      MutationOperand mutationOperand = resolveMutationOperand(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        sourceOpcode,
        opcode
      );
      if (mutationOperand.applies) {
        if (mutationOperand.valid) {
          return mutationOperand.value;
        }

        return -1;
      }

      ExpressionOperand expressionOperand = resolveExpressionOperand(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        sourceOpcode,
        opcode,
        previousStarts,
        previousCount
      );
      if (expressionOperand.applies) {
        if (expressionOperand.valid) {
          return expressionOperand.value;
        }

        return -1;
      }

      ReturnExpressionResolution returnExpression = resolveReturnExpression(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        sourceOpcode
      );
      if (returnExpression.applies) {
        if (returnExpression.primaryOperand) {
          if (returnExpression.valid) {
            return returnExpression.rightOperand;
          }

          return -1;
        }
      }

      if (twoArgumentCallStatement(sourceOpcode)) {
        if (twoArgumentCallFirstNamed(sourceOpcode)) {
          if (twoArgumentCallFirstNamed(opcode) == false) {
            ConstantResolution firstCallConstant = resolveClassConstant(
              source,
              tokenStarts,
              tokenLengths,
              twoArgumentFirstToken(statementStart),
              twoArgumentBooleanCall(opcode) == false
            );
            if (firstCallConstant.valid) {
              return firstCallConstant.value;
            }

            return -1;
          }
        }
      }
    }

    if (namedLiteralComparisonConditional(sourceOpcode)) {
      long comparisonOperandToken = literalComparisonConditionalOperandToken(
        source,
        tokenStarts,
        statementStart,
        sourceOpcode
      );
      if (loopOperandNamed(source, tokenStarts, comparisonOperandToken)) {
        ConstantResolution comparisonOperandConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          comparisonOperandToken,
          true
        );
        if (comparisonOperandConstant.valid) {
          return comparisonOperandConstant.value;
        }

        return -1;
      }
    }

    if (sourceOpcode == STATEMENT_ASSERT_EQ) {
      long globalAssertionRight = statementStart + 5;
      if (loopOperandNamed(source, tokenStarts, globalAssertionRight)) {
        ConstantResolution globalAssertionConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          globalAssertionRight,
          true
        );
        if (globalAssertionConstant.valid) {
          return globalAssertionConstant.value;
        }

        return -1;
      }
    }

    if (sourceOpcode == STATEMENT_LOCAL_LONG_NAMED) {
      if (opcode == STATEMENT_LOCAL_LONG) {
        ConstantResolution signedDeclarationConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 3,
          true
        );
        if (signedDeclarationConstant.valid) {
          return signedDeclarationConstant.value;
        }

        return -1;
      }
    }

    boolean constantBooleanLocal = sourceOpcode == STATEMENT_LOCAL_BOOLEAN_NAMED;
    if (sourceOpcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      constantBooleanLocal = true;
    }

    if (constantBooleanLocal) {
      long nameToken = statementStart + 3;
      if (sourceOpcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
        nameToken += 1;
      }

      boolean resolvedLiteral = opcode == STATEMENT_LOCAL_BOOLEAN;
      if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
        resolvedLiteral = true;
      }

      if (resolvedLiteral) {
        ConstantResolution booleanDeclarationConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          nameToken,
          false
        );
        if (booleanDeclarationConstant.valid) {
          return booleanDeclarationConstant.value;
        }

        return -1;
      }
    }

    if (sourceOpcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
        ConstantResolution signedCallConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 5,
          true
        );
        if (signedCallConstant.valid) {
          return signedCallConstant.value;
        }

        return -1;
      }
    }

    if (sourceOpcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED) {
      if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
        ConstantResolution booleanCallConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 5,
          false
        );
        if (booleanCallConstant.valid) {
          return booleanCallConstant.value;
        }

        return -1;
      }
    }

    if (sourceOpcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {
      return 0;
    }

    if (sourceOpcode == STATEMENT_RETURN_LOCAL_NAMED) {
      boolean constantSignedReturn = opcode == STATEMENT_RETURN_LONG;
      boolean constantScalarReturn = constantSignedReturn;
      if (opcode == STATEMENT_RETURN_BOOLEAN) {
        constantScalarReturn = true;
      }

      if (constantScalarReturn) {
        ConstantResolution returnConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 1,
          constantSignedReturn
        );
        if (returnConstant.valid) {
          return returnConstant.value;
        }

        return -1;
      }
    }

    if (resolvedLocalWhile(opcode)) {
      long whileConditionRight = whileConditionValueToken(source, tokenStarts, statementStart);
      if (
        localWhileConditionBit(resolvedLocalWhileForm(opcode))
          == STATEMENT_LOCAL_WHILE_CONDITION_NAMED
      ) {
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

      if (loopOperandNamed(source, tokenStarts, whileConditionRight)) {
        ConstantResolution conditionConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          whileConditionRight,
          true
        );
        if (conditionConstant.valid) {
          return conditionConstant.value;
        }

        return -1;
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

    ResolvedAssertion assertion = resolveAssertion(
      source,
      tokenStarts,
      tokenLengths,
      statementStart,
      previousStarts,
      previousCount,
      sourceOpcode
    );
    if (assertion.applies) {
      if (assertion.valid) {
        return assertion.operand;
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
      return twoArgumentFirstToken(statementStart);
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
      return literalComparisonConditionalOperandToken(
        source,
        tokenStarts,
        statementStart,
        opcode
      );
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
