//! Resolves bounded typed names through prior local declarations.

module wheeler.compiler.local_resolution;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.call_forms;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.early_return_kinds;
import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.four_argument_calls;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.named_local_update_kinds;
import wheeler.compiler.named_long_operations;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.owned_utf8_copy_loops;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.tokens;
import wheeler.compiler.two_argument_call_kinds;

classical class LocalResolution {
  private long resolutionLocalCount(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    if (opcode == STATEMENT_IF_EQ_RETURN_UTF8_CALL_NAMED) {
      return EARLY_UTF8_CALL_LOCAL_COUNT;
    }

    long earlyReturnLocals = sourceEarlyReturnLocalCount(opcode);
    if (-1 < earlyReturnLocals) {
      return earlyReturnLocals;
    }

    if (opcode == STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED) {
      if (
        ownedUtf8CopyLoopCandidate(source, tokenStarts, tokenLengths, statementStart)
      ) {
        return COPY_LOOP_FRAME_WIDTH;
      }

      return 6;
    }

    if (localUpdateSourceStatement(opcode)) {
      boolean globalUpdate = 0 < tokenLengths[COMPILER_GLOBAL_NAME_TOKEN];
      if (globalUpdate) {
        globalUpdate = sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          COMPILER_GLOBAL_NAME_TOKEN,
          statementStart
        );
      }

      if (globalUpdate) {
        return 2;
      }

      return 1;
    }

    return statementLocalCount(opcode);
  }

  private boolean declarationMatches(long opcode, boolean signed) {
    if (signed) {
      if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_UTF8_SCALAR_NAMED) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_MAP_GET_NAMED) {
        return true;
      }

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

      if (wideLocalCallStatement(opcode)) {
        return true;
      }

      if (twoArgumentCallStatement(opcode)) {
        boolean booleanResultCall = twoArgumentBooleanCall(opcode);
        if (twoArgumentBooleanSignedCall(opcode)) {
          booleanResultCall = true;
        }

        if (booleanResultCall) {} else {
          return true;
        }
      }

      if (namedLongBinary(opcode)) {
        return true;
      }

      return namedLongPair(opcode);
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return true;
    }

    if (oneArgumentBooleanCall(opcode)) {
      return true;
    }

    if (oneArgumentBooleanSignedCall(opcode)) {
      return true;
    }

    if (twoArgumentBooleanCall(opcode)) {
      return true;
    }

    if (twoArgumentBooleanSignedCall(opcode)) {
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

  /// Resolves one signed or Boolean source name without choosing its type.
  public long resolvePriorScalarDeclaration(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long assertedName
  ) {
    long signedLocal = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      assertedName,
      true
    );
    long booleanLocal = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      assertedName,
      false
    );
    if (-1 < signedLocal) {
      if (booleanLocal < 0) {
        return signedLocal;
      }

      return -1;
    }

    return booleanLocal;
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

          localBase += resolutionLocalCount(
            source,
            tokenStarts,
            tokenLengths,
            previousStart,
            previousOpcode
          );
        }
      }

      previous += 1;
    }

    if (matchCount == 1) {
      return matchedLocal;
    }

    return -1;
  }
}
