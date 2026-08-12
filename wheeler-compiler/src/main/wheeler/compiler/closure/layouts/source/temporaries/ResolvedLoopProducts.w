//! Resolves structural loop conditions to source-independent local products.

module wheeler.compiler.closure.resolved_loop_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;
import wheeler.lexer.scanner;

classical class ResolvedLoopProducts {
  private const long CONDITION_COUNT_LIMIT = 256;
  private const long CONDITION_ROWS = 1536;
  private const long CONDITION_LEFT_KIND_ROW = 256;
  private const long CONDITION_LEFT_OPERAND_ROW = 512;
  private const long CONDITION_RIGHT_KIND_ROW = 768;
  private const long CONDITION_RIGHT_OPERAND_ROW = 1024;
  private const long CONDITION_TYPE_ROW = 1280;
  private const long DOCUMENTATION_TOKEN_KIND = 5;
  private const long LINE_COMMENT_TOKEN_KIND = 4;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_ROWS = 2304;
  private const long LOOP_CONDITION_ROW = 768;
  private const long LOOP_LIMIT_START_ROW = 1024;
  private const long LOOP_LIMIT_LENGTH_ROW = 1280;
  private const long LOOP_RESOLVED_LIMIT_ROW = 1024;
  private const long LOOP_FIRST_BODY_STATEMENT_ROW = 1536;
  private const long LOOP_BODY_STATEMENT_COUNT_ROW = 1792;
  private const long LOOP_DEPTH_ROW = 2048;
  private const long LOOP_PARENT_BLOCK_ROW = 256;
  private const long LOOP_STATEMENT_ORDINAL_ROW = 512;
  private const long OPERAND_LITERAL = 0;
  private const long OPERAND_LOCAL = 1;
  private const long RESOLUTION_ARENA_BYTES = 155648;
  private const long SOURCE_CONDITION_LEFT_START_ROW = 256;
  private const long SOURCE_CONDITION_LEFT_LENGTH_ROW = 512;
  private const long SOURCE_CONDITION_RIGHT_START_ROW = 768;
  private const long SOURCE_CONDITION_RIGHT_LENGTH_ROW = 1024;
  private const long VALUE_COUNT_LIMIT = 1024;
  private const long SYMBOL_COUNT_LIMIT = 16384;
  private const long VALUE_DEFINITION_ORDINAL_ROW = 4096;
  private const long VALUE_LOCAL_ROW = 3072;
  private const long VALUE_NAME_LENGTH_ROW = 2048;
  private const long VALUE_NAME_START_ROW = 1024;
  private const long VALUE_ROWS = 7168;

  /// Reports one completely resolved structural loop product.
  public record ResolvedLoopProductPlan(long conditionCount, long loopCount, boolean valid) {}

  private record ResolvedOperand(long kind, long operand, boolean valid) {}

  private record ResolvedLimit(long value, boolean valid) {}

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
        long end = tokenStarts[token] + tokenLengths[token];
        if (end == start + length) {
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

  private ResolvedLimit resolveLimit(
    borrow utf8 source,
    long start,
    long length,
    long archiveSourceStart,
    long moduleOwner,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved
  ) {
    long token = tokenAtRange(start, length, tokenCount, tokenStarts, tokenLengths);
    if (token < 0) {
      return new ResolvedLimit(0, false);
    }

    if (tokenKinds[token] != 1) {
      if (signedNumberWidth(source, tokenKinds, tokenStarts, token) != 1) {
        return new ResolvedLimit(0, false);
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, token) == false) {
        return new ResolvedLimit(0, false);
      }

      long literal = parsedSignedNumber(source, tokenStarts, tokenLengths, token);
      if (literal < 1) {
        return new ResolvedLimit(0, false);
      }

      if (16777216 < literal) {
        return new ResolvedLimit(0, false);
      }

      return new ResolvedLimit(literal, true);
    }

    long selected = -1;
    long matches = 0;
    long symbol = 0;
    while (symbol < symbolCount) limit SYMBOL_COUNT_LIMIT {
      if (symbolOwners[symbol] == moduleOwner) {
        if (symbolTypes[symbol] == TYPE_SIGNED) {
          if (symbolResolved[symbol] == 1) {
            long symbolStart = symbolStarts[symbol] - archiveSourceStart;
            if (
              sameRange(source, start, length, symbolStart, symbolLengths[symbol])
            ) {
              selected = symbolValues[symbol];
              matches += 1;
            }
          }
        }
      }

      symbol += 1;
    }

    if (matches != 1) {
      return new ResolvedLimit(0, false);
    }

    if (selected < 1) {
      return new ResolvedLimit(0, false);
    }

    if (16777216 < selected) {
      return new ResolvedLimit(0, false);
    }

    return new ResolvedLimit(selected, true);
  }

  private boolean signedValue(
    borrow utf8 source,
    long nameStart,
    long nameLength,
    long tokenCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long nameToken = tokenAtRange(nameStart, nameLength, tokenCount, tokenStarts, tokenLengths);
    if (nameToken < 1) {
      return false;
    }

    return tokenHash(source, tokenStarts, tokenLengths, nameToken - 1) == 3327612;
  }

  private ResolvedOperand resolveOperand(
    borrow utf8 source,
    long start,
    long length,
    long owner,
    long statementOrdinal,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long valueCount,
    borrow mut words valueRows
  ) {
    long token = 0;
    long tokenMatches = 0;
    long selectedToken = -1;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenStarts[token] == start) {
        long endToken = token;
        long end = tokenStarts[token] + tokenLengths[token];
        while (end < start + length) limit 2 {
          endToken += 1;
          end = tokenStarts[endToken] + tokenLengths[endToken];
        }

        if (end == start + length) {
          selectedToken = token;
          tokenMatches += 1;
        }
      }

      token += 1;
    }

    if (tokenMatches != 1) {
      return new ResolvedOperand(0, 0, false);
    }

    if (tokenKinds[selectedToken] == 1) {
      long selectedValue = -1;
      long valueMatches = 0;
      long value = 0;
      while (value < valueCount) limit VALUE_COUNT_LIMIT {
        if (valueRows[value] == owner) {
          long definitionOrdinal = valueRows[VALUE_DEFINITION_ORDINAL_ROW + value];
          if (definitionOrdinal < statementOrdinal + 1) {
            long nameStart = valueRows[VALUE_NAME_START_ROW + value];
            long nameLength = valueRows[VALUE_NAME_LENGTH_ROW + value];
            if (sameRange(source, start, length, nameStart, nameLength)) {
              if (
                signedValue(
                  source,
                  nameStart,
                  nameLength,
                  tokenCount,
                  tokenStarts,
                  tokenLengths
                )
              ) {
                selectedValue = value;
                valueMatches += 1;
              }
            }
          }
        }

        value += 1;
      }

      if (valueMatches != 1) {
        return new ResolvedOperand(0, 0, false);
      }

      return new ResolvedOperand(
        OPERAND_LOCAL,
        valueRows[VALUE_LOCAL_ROW + selectedValue],
        true
      );
    }

    long width = signedNumberWidth(source, tokenKinds, tokenStarts, selectedToken);
    if (width < 1) {
      return new ResolvedOperand(0, 0, false);
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, selectedToken) == false) {
      return new ResolvedOperand(0, 0, false);
    }

    return new ResolvedOperand(
      OPERAND_LITERAL,
      parsedSignedNumber(source, tokenStarts, tokenLengths, selectedToken),
      true
    );
  }

  /// Resolves signed loop operands and republishes source-independent loop rows atomically.
  public ResolvedLoopProductPlan materializeResolvedLoopProducts(
    borrow utf8 source,
    long archiveSourceStart,
    long moduleOwner,
    long loopCount,
    borrow mut words sourceConditionRows,
    borrow mut words sourceLoopRows,
    long valueCount,
    borrow mut words valueRows,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut words resolvedConditionRows,
    borrow mut words resolvedLoopRows
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(sourceConditionRows) == CONDITION_ROWS);
    assert(bufferLength(sourceLoopRows) == LOOP_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(-1 < symbolCount);
    assert(symbolCount < SYMBOL_COUNT_LIMIT + 1);
    assert(bufferLength(symbolOwners) == SYMBOL_COUNT_LIMIT);
    assert(bufferLength(symbolStarts) == SYMBOL_COUNT_LIMIT);
    assert(bufferLength(symbolLengths) == SYMBOL_COUNT_LIMIT);
    assert(bufferLength(symbolTypes) == SYMBOL_COUNT_LIMIT);
    assert(bufferLength(symbolValues) == SYMBOL_COUNT_LIMIT);
    assert(bufferLength(symbolResolved) == SYMBOL_COUNT_LIMIT);
    assert(bufferLength(resolvedConditionRows) == CONDITION_ROWS);
    assert(bufferLength(resolvedLoopRows) == LOOP_ROWS);

    region staging = new region(/* bytes= */ RESOLUTION_ARENA_BYTES, /* allocations= */ 6);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words conditionUses = allocate(staging, CONDITION_COUNT_LIMIT);
    words stagedConditions = allocate(staging, CONDITION_ROWS);
    words stagedLoops = allocate(staging, LOOP_ROWS);
    boolean valid = true;
    long tokenCount = 0;
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        valid = false;
        tokenCount = diagnostic.offset - diagnostic.offset;
      }
      case ScanResult.Value(long scannedCount) {
        tokenCount = scannedCount;
      }
    }

    long readToken = 0;
    long semanticCount = 0;
    while (readToken < tokenCount) limit MAX_COMPILER_TOKENS {
      long kind = tokenKinds[readToken];
      if (kind != LINE_COMMENT_TOKEN_KIND) {
        if (kind != DOCUMENTATION_TOKEN_KIND) {
          set(tokenKinds, semanticCount, kind);
          set(tokenStarts, semanticCount, tokenStarts[readToken]);
          set(tokenLengths, semanticCount, tokenLengths[readToken]);
          semanticCount += 1;
        }
      }

      readToken += 1;
    }

    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long owner = sourceLoopRows[loop];
      long parentBlock = sourceLoopRows[LOOP_PARENT_BLOCK_ROW + loop];
      long statementOrdinal = sourceLoopRows[LOOP_STATEMENT_ORDINAL_ROW + loop];
      long condition = sourceLoopRows[LOOP_CONDITION_ROW + loop];
      long limitStart = sourceLoopRows[LOOP_LIMIT_START_ROW + loop];
      long limitLength = sourceLoopRows[LOOP_LIMIT_LENGTH_ROW + loop];
      long firstBodyStatement = sourceLoopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop];
      long bodyStatementCount = sourceLoopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
      long depth = sourceLoopRows[LOOP_DEPTH_ROW + loop];
      boolean loopValid = true;
      if (owner < 0) {
        loopValid = false;
      }

      if (63 < owner) {
        loopValid = false;
      }

      if (parentBlock < 0) {
        loopValid = false;
      }

      if (1023 < parentBlock) {
        loopValid = false;
      }

      if (statementOrdinal < 0) {
        loopValid = false;
      }

      if (condition < 0) {
        loopValid = false;
      } else {
        if (loopCount - 1 < condition) {
          loopValid = false;
        } else {
          if (conditionUses[condition] != 0) {
            loopValid = false;
          } else {
            set(conditionUses, condition, 1);
          }
        }
      }

      if (limitStart < 0) {
        loopValid = false;
      }

      if (limitLength < 1) {
        loopValid = false;
      }

      if (firstBodyStatement < 0) {
        loopValid = false;
      }

      if (4095 < firstBodyStatement) {
        loopValid = false;
      }

      if (bodyStatementCount < 0) {
        loopValid = false;
      }

      if (64 < bodyStatementCount) {
        loopValid = false;
      }

      if (4096 - firstBodyStatement < bodyStatementCount) {
        loopValid = false;
      }

      if (depth < 1) {
        loopValid = false;
      }

      if (4 < depth) {
        loopValid = false;
      }

      if (loopValid) {
        if (sourceConditionRows[condition] != owner) {
          loopValid = false;
        }
      }

      ResolvedLimit limit = new ResolvedLimit(0, false);
      ResolvedOperand left = new ResolvedOperand(0, 0, false);
      ResolvedOperand right = new ResolvedOperand(0, 0, false);
      if (loopValid) {
        limit = resolveLimit(
          source,
          limitStart,
          limitLength,
          archiveSourceStart,
          moduleOwner,
          semanticCount,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          symbolCount,
          symbolOwners,
          symbolStarts,
          symbolLengths,
          symbolTypes,
          symbolValues,
          symbolResolved
        );
        if (limit.valid == false) {
          loopValid = false;
        }
      }

      if (loopValid) {
        left = resolveOperand(
          source,
          sourceConditionRows[SOURCE_CONDITION_LEFT_START_ROW + condition],
          sourceConditionRows[SOURCE_CONDITION_LEFT_LENGTH_ROW + condition],
          owner,
          statementOrdinal,
          semanticCount,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          valueCount,
          valueRows
        );
        right = resolveOperand(
          source,
          sourceConditionRows[SOURCE_CONDITION_RIGHT_START_ROW + condition],
          sourceConditionRows[SOURCE_CONDITION_RIGHT_LENGTH_ROW + condition],
          owner,
          statementOrdinal,
          semanticCount,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          valueCount,
          valueRows
        );
        if (left.valid == false) {
          loopValid = false;
        }

        if (right.valid == false) {
          loopValid = false;
        }

        if (left.kind == OPERAND_LITERAL) {
          if (left.operand != 0) {
            loopValid = false;
          }

          if (right.kind != OPERAND_LOCAL) {
            loopValid = false;
          }
        } else {
          if (left.kind != OPERAND_LOCAL) {
            loopValid = false;
          }
        }
      }

      if (loopValid) {
        set(stagedConditions, condition, owner);
        set(stagedConditions, CONDITION_LEFT_KIND_ROW + condition, left.kind);
        set(stagedConditions, CONDITION_LEFT_OPERAND_ROW + condition, left.operand);
        set(stagedConditions, CONDITION_RIGHT_KIND_ROW + condition, right.kind);
        set(stagedConditions, CONDITION_RIGHT_OPERAND_ROW + condition, right.operand);
        set(stagedConditions, CONDITION_TYPE_ROW + condition, TYPE_SIGNED);
        set(stagedLoops, loop, owner);
        set(stagedLoops, LOOP_PARENT_BLOCK_ROW + loop, parentBlock);
        set(stagedLoops, LOOP_STATEMENT_ORDINAL_ROW + loop, statementOrdinal);
        set(stagedLoops, LOOP_CONDITION_ROW + loop, condition);
        set(stagedLoops, LOOP_RESOLVED_LIMIT_ROW + loop, limit.value);
        set(stagedLoops, LOOP_FIRST_BODY_STATEMENT_ROW + loop, firstBodyStatement);
        set(stagedLoops, LOOP_BODY_STATEMENT_COUNT_ROW + loop, bodyStatementCount);
        set(stagedLoops, LOOP_DEPTH_ROW + loop, depth);
      } else {
        valid = false;
      }

      loop += 1;
    }

    long checkedCondition = 0;
    while (checkedCondition < loopCount) limit CONDITION_COUNT_LIMIT {
      if (conditionUses[checkedCondition] != 1) {
        valid = false;
      }

      checkedCondition += 1;
    }

    if (valid) {
      long row = 0;
      while (row < CONDITION_ROWS) limit CONDITION_ROWS {
        set(resolvedConditionRows, row, stagedConditions[row]);
        row += 1;
      }

      row = 0;
      while (row < LOOP_ROWS) limit LOOP_ROWS {
        set(resolvedLoopRows, row, stagedLoops[row]);
        row += 1;
      }
    }

    drop(stagedLoops);
    drop(stagedConditions);
    drop(conditionUses);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new ResolvedLoopProductPlan(0, 0, false);
    }

    return new ResolvedLoopProductPlan(loopCount, loopCount, true);
  }
}
