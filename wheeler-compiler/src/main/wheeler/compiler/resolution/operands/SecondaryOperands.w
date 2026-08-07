//! Resolves optional second operands against typed prior declarations.

module wheeler.compiler.secondary_operands;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.class_constants;
import wheeler.compiler.conditionals;
import wheeler.compiler.early_return_operands;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.early_utf8_call_resolution;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.literal_comparison_operations;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.local_resolution;
import wheeler.compiler.loop_forms;
import wheeler.compiler.named_literal_comparison_kinds;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.operands;
import wheeler.compiler.owned_storage_forms;
import wheeler.compiler.owned_storage_operands;
import wheeler.compiler.owned_utf8_copy_loops;
import wheeler.compiler.owned_utf8_copy_resolution;
import wheeler.compiler.resolved_early_result_kinds;
import wheeler.compiler.resolved_local_loop_forms;
import wheeler.compiler.resolved_local_loop_kinds;
import wheeler.compiler.resolved_local_loop_operands;
import wheeler.compiler.return_expressions;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.tokens;
import wheeler.compiler.two_argument_call_kinds;
import wheeler.compiler.void_call_source_kinds;
import wheeler.compiler.wide_return_resolution;

classical class SecondaryOperands {
  private const long LOOP_SOURCE_FORM_COUNT = 2;

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
    long sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (wideReturnCall(opcode)) {
      return resolveWideReturnLastSources(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        opcode
      );
    }

    if (earlyUtf8Call(opcode)) {
      return resolveEarlyUtf8CallOperand(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount
      );
    }

    boolean wideVoidCall = sourceOpcode == STATEMENT_CALL_VOID_TWO_NAMED;
    if (sourceOpcode == STATEMENT_CALL_VOID_THREE_NAMED) {
      wideVoidCall = true;
    }

    if (wideVoidCall) {
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

    if (sourceOpcode == STATEMENT_CALL_VOID_ZERO_NAMED) {
      return 0;
    }

    if (sourceOpcode == STATEMENT_CALL_VOID_ONE_NAMED) {
      return 0;
    }

    if (ownedStorageStatement(sourceOpcode)) {
      return ownedStorageSecondaryOperand(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart,
        sourceOpcode
      );
    }

    boolean borrowedWrite = sourceOpcode == STATEMENT_SET_WORD_NAMED;
    if (sourceOpcode == STATEMENT_SET_BYTE_NAMED) {
      borrowedWrite = true;
    }

    if (sourceOpcode == STATEMENT_MAP_PUT_NAMED) {
      borrowedWrite = true;
    }

    if (borrowedWrite) {
      long writeIndex = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 4,
        true
      );
      long writeValue = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 6,
        true
      );
      if (-1 < writeIndex) {
        if (-1 < writeValue) {
          return writeIndex * INTRINSIC_LOCAL_SOURCE_COUNT + writeValue;
        }
      }

      return -1;
    }

    if (sourceOpcode == STATEMENT_RETURN_BUFFER_GET_NAMED) {
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

    boolean directIndexedIntrinsic = sourceOpcode == STATEMENT_RETURN_UTF8_SCALAR_NAMED;
    if (sourceOpcode == STATEMENT_RETURN_UTF8_WIDTH_NAMED) {
      directIndexedIntrinsic = true;
    }

    if (sourceOpcode == STATEMENT_RETURN_MAP_GET_NAMED) {
      directIndexedIntrinsic = true;
    }

    if (sourceOpcode == STATEMENT_RETURN_MAP_HAS_NAMED) {
      directIndexedIntrinsic = true;
    }

    if (directIndexedIntrinsic) {
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

    if (sourceOpcode == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
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

    boolean indexedIntrinsic = sourceOpcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED;
    if (sourceOpcode == STATEMENT_LOCAL_MAP_GET_NAMED) {
      indexedIntrinsic = true;
    }

    if (sourceOpcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
      indexedIntrinsic = true;
    }

    if (indexedIntrinsic) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 7,
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
        statementStart + 7,
        true
      );
    }

    if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 11,
        true
      );
    }

    if (resolvedEarlyLocalReturn(opcode)) {
      long returnToken = earlyComparisonReturnToken(source, tokenStarts, statementStart, opcode);
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        returnToken,
        true
      );
    }

    EarlyReturnOperand earlyReturn = resolveEarlyReturnSecondaryOperand(
      source,
      tokenStarts,
      tokenLengths,
      statementStart,
      opcode
    );
    if (earlyReturn.applies) {
      return earlyReturn.value;
    }

    if (ownedUtf8CopyLoop(opcode)) {
      return resolveOwnedUtf8CopySecondaryOperand(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount
      );
    }

    if (resolvedLocalWhile(opcode)) {
      long loopLimit = whileLimitToken(source, tokenStarts, statementStart);
      if (
        localWhileLimitPair(resolvedLocalWhileForm(opcode)) % LOOP_SOURCE_FORM_COUNT == 1
      ) {
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

      if (loopOperandNamed(source, tokenStarts, loopLimit)) {
        ConstantResolution limitConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          loopLimit,
          true
        );
        if (limitConstant.valid) {
          return limitConstant.value;
        }

        return -1;
      }

      return parsedSignedNumber(source, tokenStarts, tokenLengths, loopLimit);
    }

    if (returnLocalBinaryStatement(sourceOpcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        true
      );
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
        if (returnLocalPairStatement(sourceOpcode)) {
          return resolvePriorDeclaration(
            source,
            tokenStarts,
            tokenLengths,
            previousStarts,
            previousCount,
            statementStart + 1,
            true
          );
        }
      } else {
        if (returnExpression.valid) {
          return returnExpression.rightOperand;
        }

        return -1;
      }
    }

    if (-1 < opcode) {
      if (twoArgumentCallStatement(sourceOpcode)) {
        if (twoArgumentCallSecondNamed(sourceOpcode)) {
          if (twoArgumentCallSecondNamed(opcode) == false) {
            ConstantResolution secondCallConstant = resolveClassConstant(
              source,
              tokenStarts,
              tokenLengths,
              twoArgumentSecondToken(source, tokenStarts, statementStart),
              twoArgumentBooleanCall(opcode) == false
            );
            if (secondCallConstant.valid) {
              return secondCallConstant.value;
            }

            return -1;
          }
        }
      }
    }

    if (wideLocalCallStatement(opcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        threeArgumentSecondToken(statementStart),
        true
      );
    }

    if (twoArgumentCallStatement(opcode)) {
      long secondToken = twoArgumentSecondToken(source, tokenStarts, statementStart);
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

      if (loopOperandNamed(source, tokenStarts, comparisonToken)) {
        ConstantResolution comparisonConstant = resolveClassConstant(
          source,
          tokenStarts,
          tokenLengths,
          comparisonToken,
          true
        );
        if (comparisonConstant.valid) {
          return comparisonConstant.value;
        }

        return -1;
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
}
