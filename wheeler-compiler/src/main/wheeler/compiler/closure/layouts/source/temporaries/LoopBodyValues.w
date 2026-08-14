//! Resolves loop-body names and scalar types against callable value products.

module wheeler.compiler.closure.loop_body_values;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class LoopBodyValues {
  private const long MAX_LOCALS = 256;
  private const long VALUE_COUNT_LIMIT = 1024;
  private const long VALUE_DEFINITION_ORDINAL_ROW = 4096;
  private const long VALUE_LOCAL_ROW = 3072;
  private const long VALUE_NAME_LENGTH_ROW = 2048;
  private const long VALUE_NAME_START_ROW = 1024;

  /// Reports one exact visible callable value.
  public record LoopBodyValue(long local, boolean valid) {}

  /// Reports one Boolean declaration resolved against prior callable values.
  public record LoopBooleanDeclaration(long localBase, long opcode, long operand, boolean valid) {}

  /// Resolves one Boolean literal or signed-local equality declaration.
  public LoopBooleanDeclaration resolveLoopBooleanDeclaration(
    borrow utf8 source,
    long token,
    long owner,
    long ordinal,
    long valueCount,
    borrow mut words valueRows,
    long semanticCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    LoopBodyValue declaration = resolveLoopBodyValue(
      source,
      tokenStarts[token + 1],
      tokenLengths[token + 1],
      owner,
      ordinal + 1,
      valueCount,
      valueRows
    );
    if (declaration.valid == false) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    long localBase = declaration.local - 1;
    long valueToken = token + 3;
    long literal = tokenHash(source, tokenStarts, tokenLengths, valueToken);
    if (literal == TOKEN_TRUE) {
      return new LoopBooleanDeclaration(localBase, BODY_BOOLEAN_LITERAL, 1, true);
    }

    if (literal == TOKEN_FALSE) {
      return new LoopBooleanDeclaration(localBase, BODY_BOOLEAN_LITERAL, 0, true);
    }

    if (tokenKinds[valueToken] != 1) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    LoopBodyValue comparisonSource = resolveLoopBodyValue(
      source,
      tokenStarts[valueToken],
      tokenLengths[valueToken],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (comparisonSource.valid == false) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        comparisonSource.local,
        valueCount,
        valueRows,
        semanticCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, valueToken + 1, PUNCTUATION_ASSIGN) == false
    ) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, valueToken + 2, PUNCTUATION_ASSIGN) == false
    ) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    long comparisonLiteral = valueToken + 3;
    if (signedNumberWidth(source, tokenKinds, tokenStarts, comparisonLiteral) != 1) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    if (
      signedNumberValid(source, tokenStarts, tokenLengths, comparisonLiteral) == false
    ) {
      return new LoopBooleanDeclaration(0, 0, 0, false);
    }

    return new LoopBooleanDeclaration(
      localBase - 2,
      BODY_BOOLEAN_EQ_LITERAL_BASE + comparisonSource.local,
      parsedSignedNumber(source, tokenStarts, tokenLengths, comparisonLiteral),
      true
    );
  }

  /// Reports one resolved direct loop assertion.
  public record LoopAssertion(long opcode, long operandKind, long operand, boolean valid) {}

  /// Resolves Boolean, local-to-literal, and literal-to-local assertions.
  public LoopAssertion resolveLoopAssertion(
    borrow utf8 source,
    long token,
    long owner,
    long ordinal,
    long valueCount,
    borrow mut words valueRows,
    long semanticCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return new LoopAssertion(0, 0, 0, false);
    }

    long leftToken = token + 2;
    if (tokenKinds[leftToken] != 1) {
      long leftWidth = signedNumberWidth(source, tokenKinds, tokenStarts, leftToken);
      if (leftWidth < 1) {
        return new LoopAssertion(0, 0, 0, false);
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, leftToken) == false) {
        return new LoopAssertion(0, 0, 0, false);
      }

      long reversedComparisonToken = leftToken + leftWidth;
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          reversedComparisonToken,
          PUNCTUATION_LESS_THAN
        ) == false
      ) {
        return new LoopAssertion(0, 0, 0, false);
      }

      long reversedRightToken = reversedComparisonToken + 1;
      LoopBodyValue right = resolveLoopBodyValue(
        source,
        tokenStarts[reversedRightToken],
        tokenLengths[reversedRightToken],
        owner,
        ordinal,
        valueCount,
        valueRows
      );
      if (right.valid == false) {
        return new LoopAssertion(0, 0, 0, false);
      }

      if (
        signedLoopBodyLocal(
          source,
          owner,
          right.local,
          valueCount,
          valueRows,
          semanticCount,
          tokenStarts,
          tokenLengths
        ) == false
      ) {
        return new LoopAssertion(0, 0, 0, false);
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          reversedRightToken + 1,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return new LoopAssertion(0, 0, 0, false);
      }

      return new LoopAssertion(
        BODY_ASSERT_LITERAL_LT_BASE + right.local,
        0,
        parsedSignedNumber(source, tokenStarts, tokenLengths, leftToken),
        true
      );
    }

    LoopBodyValue left = resolveLoopBodyValue(
      source,
      tokenStarts[leftToken],
      tokenLengths[leftToken],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (left.valid == false) {
      return new LoopAssertion(0, 0, 0, false);
    }

    long comparisonToken = leftToken + 1;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, comparisonToken, PUNCTUATION_CLOSE_PAREN)
    ) {
      return new LoopAssertion(BODY_ASSERT_BOOLEAN, 1, left.local, true);
    }

    long assertionBase = -1;
    long sourceToken = comparisonToken + 1;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, comparisonToken, PUNCTUATION_LESS_THAN)
    ) {
      assertionBase = BODY_ASSERT_LT_LITERAL_BASE;
    } else {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, comparisonToken, PUNCTUATION_ASSIGN)
      ) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            comparisonToken + 1,
            PUNCTUATION_ASSIGN
          )
        ) {
          assertionBase = BODY_ASSERT_EQ_LITERAL_BASE;
          sourceToken += 1;
        }
      }
    }

    if (assertionBase < 0) {
      return new LoopAssertion(0, 0, 0, false);
    }

    if (tokenKinds[sourceToken] == 1) {
      if (assertionBase != BODY_ASSERT_LT_LITERAL_BASE) {
        return new LoopAssertion(0, 0, 0, false);
      }

      LoopBodyValue localRight = resolveLoopBodyValue(
        source,
        tokenStarts[sourceToken],
        tokenLengths[sourceToken],
        owner,
        ordinal,
        valueCount,
        valueRows
      );
      if (localRight.valid == false) {
        return new LoopAssertion(0, 0, 0, false);
      }

      if (
        signedLoopBodyLocal(
          source,
          owner,
          localRight.local,
          valueCount,
          valueRows,
          semanticCount,
          tokenStarts,
          tokenLengths
        ) == false
      ) {
        return new LoopAssertion(0, 0, 0, false);
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          sourceToken + 1,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return new LoopAssertion(0, 0, 0, false);
      }

      return new LoopAssertion(
        BODY_ASSERT_LOCAL_LT_BASE + left.local,
        1,
        localRight.local,
        true
      );
    }

    long sourceWidth = signedNumberWidth(source, tokenKinds, tokenStarts, sourceToken);
    if (sourceWidth < 1) {
      return new LoopAssertion(0, 0, 0, false);
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, sourceToken) == false) {
      return new LoopAssertion(0, 0, 0, false);
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        sourceToken + sourceWidth,
        PUNCTUATION_CLOSE_PAREN
      ) == false
    ) {
      return new LoopAssertion(0, 0, 0, false);
    }

    return new LoopAssertion(
      assertionBase + left.local,
      0,
      parsedSignedNumber(source, tokenStarts, tokenLengths, sourceToken),
      true
    );
  }

  /// Returns the next statement in strict source order.
  public long nextLoopBodyStatement(
    long priorStart,
    long statementCount,
    borrow mut words statementRows,
    long statementStartRow
  ) {
    long selected = statementCount;
    long selectedStart = 16777217;
    long candidate = 0;
    while (candidate < statementCount) limit 4096 {
      long candidateStart = statementRows[statementStartRow + candidate];
      if (priorStart < candidateStart) {
        if (candidateStart < selectedStart) {
          selected = candidate;
          selectedStart = candidateStart;
        }
      }

      candidate += 1;
    }

    return selected;
  }

  /// Returns the lowest statement block owned by one callable.
  public long loopBodyRootBlockForOwner(
    long owner,
    long statementCount,
    borrow mut words statementRows
  ) {
    long root = 4096;
    long statement = 0;
    while (statement < statementCount) limit 4096 {
      if (statementRows[statement] == owner) {
        long block = statementRows[4096 + statement];
        if (block < root) {
          root = block;
        }
      }

      statement += 1;
    }

    return root;
  }

  /// Returns the unique token at one exact source start.
  public long tokenAtStart(long start, long tokenCount, borrow mut words tokenStarts) {
    long selected = -1;
    long matches = 0;
    long token = 0;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenStarts[token] == start) {
        selected = token;
        matches += 1;
      }

      token += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Returns the first local coordinate free before one statement ordinal.
  public long localBaseAtOrdinal(
    long owner,
    long ordinal,
    long valueCount,
    borrow mut words valueRows
  ) {
    long localBase = 0;
    long value = 0;
    while (value < valueCount) limit VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[VALUE_DEFINITION_ORDINAL_ROW + value] < ordinal + 1) {
          long local = valueRows[VALUE_LOCAL_ROW + value] + 1;
          if (localBase < local) {
            localBase = local;
          }
        }
      }

      value += 1;
    }

    return localBase;
  }

  /// Compacts semantic tokens in place and returns their count.
  public long compactLoopBodyTokens(
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long readToken = 0;
    long semanticCount = 0;
    while (readToken < tokenCount) limit MAX_COMPILER_TOKENS {
      long kind = tokenKinds[readToken];
      if (kind != 4) {
        if (kind != 5) {
          set(tokenKinds, semanticCount, kind);
          set(tokenStarts, semanticCount, tokenStarts[readToken]);
          set(tokenLengths, semanticCount, tokenLengths[readToken]);
          semanticCount += 1;
        }
      }

      readToken += 1;
    }

    return semanticCount;
  }

  private long tokenAtRange(
    long start,
    long length,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long selected = -1;
    long matches = 0;
    long token = 0;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenStarts[token] == start) {
        if (tokenLengths[token] == length) {
          selected = token;
          matches += 1;
        }
      }

      token += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private boolean sameRange(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength != rightLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftLength) limit 256 {
      if (
        utf8Scalar(source, leftStart + offset) != utf8Scalar(source, rightStart + offset)
      ) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Resolves one uniquely visible name before the selected source ordinal.
  public LoopBodyValue resolveLoopBodyValue(
    borrow utf8 source,
    long start,
    long length,
    long owner,
    long ordinal,
    long valueCount,
    borrow mut words valueRows
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[VALUE_DEFINITION_ORDINAL_ROW + value] < ordinal + 1) {
          if (
            sameRange(
              source,
              start,
              length,
              valueRows[VALUE_NAME_START_ROW + value],
              valueRows[VALUE_NAME_LENGTH_ROW + value]
            )
          ) {
            selected = valueRows[VALUE_LOCAL_ROW + value];
            matches += 1;
          }
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return new LoopBodyValue(0, false);
    }

    if (selected < 0) {
      return new LoopBodyValue(0, false);
    }

    if (MAX_LOCALS - 1 < selected) {
      return new LoopBodyValue(0, false);
    }

    return new LoopBodyValue(selected, true);
  }

  /// Reports whether one unique callable local has Boolean type.
  public boolean booleanLoopBodyLocal(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    return loopBodyValueType(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    ) == TOKEN_BOOLEAN;
  }

  /// Reports whether one unique callable local has signed type.
  public boolean signedLoopBodyLocal(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    return loopBodyValueType(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    ) == TOKEN_LONG;
  }

  /// Reports whether one unique callable local has borrowed-word type.
  public boolean wordsLoopBodyLocal(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    return loopBodyValueType(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    ) == TOKEN_WORDS;
  }

  /// Reports whether one borrowed-word local requires an owner reborrow temporary.
  public boolean borrowedWordsLoopBodyLocal(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (
      loopBodyValueType(
        source,
        owner,
        local,
        valueCount,
        valueRows,
        tokenCount,
        tokenStarts,
        tokenLengths
      ) != TOKEN_WORDS
    ) {
      return false;
    }

    return borrowedLoopBodyLocal(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      tokenCount,
      tokenStarts,
      tokenLengths
    );
  }

  /// Reports whether one token hash names a supported buffer write intrinsic.
  public boolean loopBufferSetToken(long hash) {
    if (hash == TOKEN_SET) {
      return true;
    }

    return hash == TOKEN_SET_BYTE;
  }

  /// Reports whether one source local carries an explicit borrow mode.
  public boolean borrowedLoopBodyLocal(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[VALUE_LOCAL_ROW + value] == local) {
          selected = value;
          matches += 1;
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return false;
    }

    long nameToken = tokenAtRange(
      valueRows[VALUE_NAME_START_ROW + selected],
      valueRows[VALUE_NAME_LENGTH_ROW + selected],
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (1 < nameToken) {
      if (tokenHash(source, tokenStarts, tokenLengths, nameToken - 2) == TOKEN_BORROW) {
        return true;
      }
    }

    if (2 < nameToken) {
      if (tokenHash(source, tokenStarts, tokenLengths, nameToken - 3) == TOKEN_BORROW) {
        return true;
      }
    }

    return false;
  }

  /// Returns the source type token hash for one unique callable local.
  public long loopBodyValueType(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[VALUE_LOCAL_ROW + value] == local) {
          selected = value;
          matches += 1;
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return -1;
    }

    long nameToken = tokenAtRange(
      valueRows[VALUE_NAME_START_ROW + selected],
      valueRows[VALUE_NAME_LENGTH_ROW + selected],
      tokenCount,
      tokenStarts,
      tokenLengths
    );
    if (nameToken < 1) {
      return -1;
    }

    return tokenHash(source, tokenStarts, tokenLengths, nameToken - 1);
  }
}
