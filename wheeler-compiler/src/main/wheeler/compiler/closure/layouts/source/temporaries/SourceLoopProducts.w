//! Publishes callable-local structural statement and loop products.

module wheeler.compiler.closure.source_loop_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceLoopProducts {
  private const long BLOCK_COUNT_LIMIT = 1024;
  private const long BLOCK_ROWS = 6144;
  private const long BLOCK_PARENT_ROW = 1024;
  private const long BLOCK_DEPTH_ROW = 2048;
  private const long BLOCK_START_ROW = 3072;
  private const long BLOCK_LENGTH_ROW = 4096;
  private const long BLOCK_ORDINAL_ROW = 5120;
  private const long CALLABLE_COUNT_LIMIT = 64;
  private const long CONDITION_COUNT_LIMIT = 256;
  private const long CONDITION_ROWS = 1536;
  private const long CONDITION_LEFT_START_ROW = 256;
  private const long CONDITION_LEFT_LENGTH_ROW = 512;
  private const long CONDITION_RIGHT_START_ROW = 768;
  private const long CONDITION_RIGHT_LENGTH_ROW = 1024;
  private const long CONDITION_REVERSED_ROW = 1280;
  private const long DOCUMENTATION_TOKEN_KIND = 5;
  private const long LINE_COMMENT_TOKEN_KIND = 4;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_ROWS = 2304;
  private const long LOOP_PARENT_BLOCK_ROW = 256;
  private const long LOOP_STATEMENT_ORDINAL_ROW = 512;
  private const long LOOP_CONDITION_ROW = 768;
  private const long LOOP_LIMIT_START_ROW = 1024;
  private const long LOOP_LIMIT_LENGTH_ROW = 1280;
  private const long LOOP_FIRST_BODY_STATEMENT_ROW = 1536;
  private const long LOOP_BODY_STATEMENT_COUNT_ROW = 1792;
  private const long LOOP_DEPTH_ROW = 2048;
  private const long MAX_LOOP_LIMIT = 16777216;
  private const long MAX_STATEMENTS = 4096;
  private const long MAX_STATEMENTS_PER_BLOCK = 64;
  private const long SOURCE_LOOP_ARENA_BYTES = 474112;
  private const long STATEMENT_ROWS = 28672;
  private const long STATEMENT_BLOCK_ROW = 4096;
  private const long STATEMENT_ORDINAL_ROW = 8192;
  private const long STATEMENT_START_ROW = 12288;
  private const long STATEMENT_LENGTH_ROW = 16384;
  private const long STATEMENT_FIRST_CHILD_ROW = 20480;
  private const long STATEMENT_CHILD_COUNT_ROW = 24576;

  /// Reports one complete structural statement and loop indexing pass.
  public record SourceLoopProductPlan(
    long statementCount,
    long conditionCount,
    long loopCount,
    boolean valid
  ) {}

  private long childBlockAtToken(
    long parent,
    long openToken,
    long blockCount,
    borrow mut words blockParents,
    borrow mut words blockOpenTokens
  ) {
    long block = 0;
    long selected = -1;
    while (block < blockCount) limit BLOCK_COUNT_LIMIT {
      if (blockParents[block] == parent) {
        if (blockOpenTokens[block] == openToken) {
          if (-1 < selected) {
            return -1;
          }

          selected = block;
        }
      }

      block += 1;
    }

    return selected;
  }

  private long operandWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    if (tokenKinds[token] == 1) {
      return 1;
    }

    long width = signedNumberWidth(source, tokenKinds, tokenStarts, token);
    if (width < 1) {
      return -1;
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, token) == false) {
      return -1;
    }

    return width;
  }

  private record SourceLoopHeader(
    long leftToken,
    long leftWidth,
    long rightToken,
    long rightWidth,
    long limitToken,
    long limitWidth,
    long reversed,
    boolean valid
  ) {}

  private SourceLoopHeader invalidSourceLoopHeader() {
    return new SourceLoopHeader(0, 0, 0, 0, 0, 0, 0, false);
  }

  private SourceLoopHeader parseSourceLoopHeader(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long startToken,
    long bodyOpenToken
  ) {
    if (bodyOpenToken < startToken + 4) {
      return invalidSourceLoopHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, startToken + 1, PUNCTUATION_OPEN_PAREN)
        == false
    ) {
      return invalidSourceLoopHeader();
    }

    long leftToken = startToken + 2;
    long leftWidth = operandWidth(source, tokenKinds, tokenStarts, tokenLengths, leftToken);
    if (leftWidth < 1) {
      return invalidSourceLoopHeader();
    }

    long lessToken = leftToken + leftWidth;
    if (bodyOpenToken < lessToken + 2) {
      return invalidSourceLoopHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, lessToken, PUNCTUATION_LESS_THAN) == false
    ) {
      return invalidSourceLoopHeader();
    }

    long rightToken = lessToken + 1;
    long rightWidth = operandWidth(source, tokenKinds, tokenStarts, tokenLengths, rightToken);
    if (rightWidth < 1) {
      return invalidSourceLoopHeader();
    }

    long closeCondition = rightToken + rightWidth;
    if (bodyOpenToken < closeCondition + 3) {
      return invalidSourceLoopHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeCondition, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return invalidSourceLoopHeader();
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, closeCondition + 1) != TOKEN_LIMIT
    ) {
      return invalidSourceLoopHeader();
    }

    long limitToken = closeCondition + 2;
    long limitWidth = operandWidth(source, tokenKinds, tokenStarts, tokenLengths, limitToken);
    if (limitWidth < 1) {
      return invalidSourceLoopHeader();
    }

    if (limitToken + limitWidth != bodyOpenToken) {
      return invalidSourceLoopHeader();
    }

    if (tokenKinds[limitToken] != 1) {
      long limit = parsedSignedNumber(source, tokenStarts, tokenLengths, limitToken);
      if (limit < 1) {
        return invalidSourceLoopHeader();
      }

      if (MAX_LOOP_LIMIT < limit) {
        return invalidSourceLoopHeader();
      }
    }

    boolean leftNamed = tokenKinds[leftToken] == 1;
    boolean rightNamed = tokenKinds[rightToken] == 1;
    long reversed = 0;
    if (leftNamed == false) {
      if (rightNamed == false) {
        return invalidSourceLoopHeader();
      }

      long leftValue = parsedSignedNumber(source, tokenStarts, tokenLengths, leftToken);
      if (leftValue != 0) {
        return invalidSourceLoopHeader();
      }

      reversed = 1;
    }

    return new SourceLoopHeader(
      leftToken,
      leftWidth,
      rightToken,
      rightWidth,
      limitToken,
      limitWidth,
      reversed,
      true
    );
  }

  /// Publishes block-grouped statements, comparison products, and bounded loop rows atomically.
  public SourceLoopProductPlan materializeSourceLoopProducts(
    borrow utf8 source,
    long blockCount,
    borrow mut words blockRows,
    borrow mut words statementRows,
    borrow mut words conditionRows,
    borrow mut words loopRows
  ) {
    assert(-1 < blockCount);
    assert(blockCount < BLOCK_COUNT_LIMIT + 1);
    assert(bufferLength(blockRows) == BLOCK_ROWS);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(bufferLength(conditionRows) == CONDITION_ROWS);
    assert(bufferLength(loopRows) == LOOP_ROWS);

    region staging = new region(/* bytes= */ SOURCE_LOOP_ARENA_BYTES, /* allocations= */ 16);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words blockParents = allocate(staging, BLOCK_COUNT_LIMIT);
    words blockOpenTokens = allocate(staging, BLOCK_COUNT_LIMIT);
    words blockCloseTokens = allocate(staging, BLOCK_COUNT_LIMIT);
    words blockFirstStatements = allocate(staging, BLOCK_COUNT_LIMIT);
    words blockStatementCounts = allocate(staging, BLOCK_COUNT_LIMIT);
    words blockUses = allocate(staging, BLOCK_COUNT_LIMIT);
    words functionBlockCounts = allocate(staging, CALLABLE_COUNT_LIMIT);
    words stagedStatements = allocate(staging, STATEMENT_ROWS);
    words statementTokens = allocate(staging, MAX_STATEMENTS);
    words statementAtTokens = allocate(staging, MAX_COMPILER_TOKENS);
    words functionOrdinals = allocate(staging, CALLABLE_COUNT_LIMIT);
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

    long block = 0;
    while (block < blockCount) limit BLOCK_COUNT_LIMIT {
      long blockOwner = blockRows[block];
      long parent = blockRows[BLOCK_PARENT_ROW + block];
      long depth = blockRows[BLOCK_DEPTH_ROW + block];
      long start = blockRows[BLOCK_START_ROW + block];
      long length = blockRows[BLOCK_LENGTH_ROW + block];
      long blockOrdinal = blockRows[BLOCK_ORDINAL_ROW + block];
      boolean blockValid = true;
      if (blockOwner < 0) {
        blockValid = false;
      } else {
        if (CALLABLE_COUNT_LIMIT - 1 < blockOwner) {
          blockValid = false;
        }
      }

      if (parent < -1) {
        blockValid = false;
      } else {
        if (block - 1 < parent) {
          blockValid = false;
        } else {
          if (parent < 0) {
            if (depth != 0) {
              blockValid = false;
            }
          } else {
            if (blockRows[parent] != blockOwner) {
              blockValid = false;
            }

            if (depth != blockRows[BLOCK_DEPTH_ROW + parent] + 1) {
              blockValid = false;
            }
          }
        }
      }

      if (blockOrdinal < 0) {
        blockValid = false;
      } else {
        if (blockValid) {
          if (blockOrdinal != functionBlockCounts[blockOwner]) {
            blockValid = false;
          } else {
            set(functionBlockCounts, blockOwner, blockOrdinal + 1);
          }
        }
      }

      if (length < 2) {
        blockValid = false;
      }

      if (start < 0) {
        blockValid = false;
      } else {
        if (bufferLength(source) < start) {
          blockValid = false;
        } else {
          if (bufferLength(source) - start < length) {
            blockValid = false;
          }
        }
      }

      long openToken = -1;
      long closeToken = -1;
      if (blockValid) {
        long blockToken = 0;
        long blockEnd = start + length;
        while (blockToken < semanticCount) limit MAX_COMPILER_TOKENS {
          if (tokenStarts[blockToken] == start) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                blockToken,
                PUNCTUATION_OPEN_BRACE
              )
            ) {
              openToken = blockToken;
            }
          }

          if (tokenStarts[blockToken] + tokenLengths[blockToken] == blockEnd) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                blockToken,
                PUNCTUATION_CLOSE_BRACE
              )
            ) {
              closeToken = blockToken;
            }
          }

          blockToken += 1;
        }
      }

      if (openToken < 0) {
        blockValid = false;
      }

      if (closeToken < openToken) {
        blockValid = false;
      }

      if (blockValid) {
        if (-1 < parent) {
          if (openToken < blockOpenTokens[parent] + 1) {
            blockValid = false;
          }

          if (blockCloseTokens[parent] < closeToken + 1) {
            blockValid = false;
          }
        }
      }

      if (blockValid == false) {
        valid = false;
      }

      set(blockParents, block, parent);
      set(blockOpenTokens, block, openToken);
      set(blockCloseTokens, block, closeToken);
      block += 1;
    }

    long statementCount = 0;
    block = 0;
    while (block < blockCount) limit BLOCK_COUNT_LIMIT {
      set(blockFirstStatements, block, statementCount);
      long directCount = 0;
      long cursor = blockOpenTokens[block] + 1;
      long directCloseToken = blockCloseTokens[block];
      while (cursor < directCloseToken) limit MAX_COMPILER_TOKENS {
        long statementStartToken = cursor;
        long statementEndToken = -1;
        long statementChild = -1;
        boolean searching = true;
        while (searching) limit MAX_COMPILER_TOKENS {
          if (directCloseToken < cursor + 1) {
            valid = false;
            searching = false;
          } else {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_SEMICOLON)
            ) {
              statementEndToken = cursor;
              searching = false;
            } else {
              if (
                punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_BRACE)
              ) {
                statementChild = childBlockAtToken(
                  block,
                  cursor,
                  blockCount,
                  blockParents,
                  blockOpenTokens
                );
                if (statementChild < 0) {
                  valid = false;
                  searching = false;
                } else {
                  if (blockUses[statementChild] != 0) {
                    valid = false;
                  }

                  set(blockUses, statementChild, blockUses[statementChild] + 1);
                  statementEndToken = blockCloseTokens[statementChild];
                  searching = false;
                }
              } else {
                cursor += 1;
              }
            }
          }
        }

        if (MAX_STATEMENTS < statementCount + 1) {
          valid = false;
        } else {
          if (MAX_STATEMENTS_PER_BLOCK < directCount + 1) {
            valid = false;
          } else {
            if (statementEndToken < statementStartToken) {
              valid = false;
            } else {
              long statementStart = tokenStarts[statementStartToken];
              long statementEnd = tokenStarts[statementEndToken] + tokenLengths[statementEndToken];
              set(stagedStatements, statementCount, blockRows[block]);
              set(stagedStatements, STATEMENT_BLOCK_ROW + statementCount, block);
              set(stagedStatements, STATEMENT_START_ROW + statementCount, statementStart);
              set(
                stagedStatements,
                STATEMENT_LENGTH_ROW + statementCount,
                statementEnd - statementStart
              );
              set(stagedStatements, STATEMENT_FIRST_CHILD_ROW + statementCount, statementChild);
              long childCount = 0;
              if (-1 < statementChild) {
                childCount = 1;
              }

              set(stagedStatements, STATEMENT_CHILD_COUNT_ROW + statementCount, childCount);
              set(statementTokens, statementCount, statementStartToken);
              set(statementAtTokens, statementStartToken, statementCount + 1);
              statementCount += 1;
              directCount += 1;
            }
          }
        }

        if (statementEndToken < 0) {
          cursor = directCloseToken;
        } else {
          cursor = statementEndToken + 1;
        }
      }

      if (cursor != directCloseToken) {
        valid = false;
      }

      set(blockStatementCounts, block, directCount);
      block += 1;
    }

    block = 0;
    while (block < blockCount) limit BLOCK_COUNT_LIMIT {
      if (blockParents[block] < 0) {
        if (blockUses[block] != 0) {
          valid = false;
        }
      } else {
        if (blockUses[block] != 1) {
          valid = false;
        }
      }

      block += 1;
    }

    long ordinalToken = 0;
    while (ordinalToken < semanticCount) limit MAX_COMPILER_TOKENS {
      long ordinalStatement = statementAtTokens[ordinalToken] - 1;
      if (-1 < ordinalStatement) {
        long ordinalOwner = stagedStatements[ordinalStatement];
        long sourceOrdinal = functionOrdinals[ordinalOwner];
        set(stagedStatements, STATEMENT_ORDINAL_ROW + ordinalStatement, sourceOrdinal);
        set(functionOrdinals, ordinalOwner, sourceOrdinal + 1);
      }

      ordinalToken += 1;
    }

    long conditionCount = 0;
    long loopCount = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      long startToken = statementTokens[statement];
      if (tokenHash(source, tokenStarts, tokenLengths, startToken) == TOKEN_WHILE) {
        long child = stagedStatements[STATEMENT_FIRST_CHILD_ROW + statement];
        boolean loopValid = true;
        if (child < 0) {
          loopValid = false;
        }

        if (stagedStatements[STATEMENT_CHILD_COUNT_ROW + statement] != 1) {
          loopValid = false;
        }

        if (LOOP_COUNT_LIMIT - 1 < loopCount) {
          loopValid = false;
        }

        if (CONDITION_COUNT_LIMIT - 1 < conditionCount) {
          loopValid = false;
        }

        SourceLoopHeader header = invalidSourceLoopHeader();
        if (loopValid) {
          header = parseSourceLoopHeader(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            startToken,
            blockOpenTokens[child]
          );
          if (header.valid == false) {
            loopValid = false;
          }
        }

        if (loopValid) {
          long leftStart = tokenStarts[header.leftToken];
          long leftEndToken = header.leftToken + header.leftWidth - 1;
          long leftEnd = tokenStarts[leftEndToken] + tokenLengths[leftEndToken];
          long rightStart = tokenStarts[header.rightToken];
          long rightEndToken = header.rightToken + header.rightWidth - 1;
          long rightEnd = tokenStarts[rightEndToken] + tokenLengths[rightEndToken];
          set(stagedConditions, conditionCount, stagedStatements[statement]);
          set(stagedConditions, CONDITION_LEFT_START_ROW + conditionCount, leftStart);
          set(stagedConditions, CONDITION_LEFT_LENGTH_ROW + conditionCount, leftEnd - leftStart);
          set(stagedConditions, CONDITION_RIGHT_START_ROW + conditionCount, rightStart);
          set(
            stagedConditions,
            CONDITION_RIGHT_LENGTH_ROW + conditionCount,
            rightEnd - rightStart
          );
          set(stagedConditions, CONDITION_REVERSED_ROW + conditionCount, header.reversed);
          set(stagedLoops, loopCount, stagedStatements[statement]);
          set(
            stagedLoops,
            LOOP_PARENT_BLOCK_ROW + loopCount,
            stagedStatements[STATEMENT_BLOCK_ROW + statement]
          );
          set(
            stagedLoops,
            LOOP_STATEMENT_ORDINAL_ROW + loopCount,
            stagedStatements[STATEMENT_ORDINAL_ROW + statement]
          );
          set(stagedLoops, LOOP_CONDITION_ROW + loopCount, conditionCount);
          long limitStart = tokenStarts[header.limitToken];
          long limitEndToken = header.limitToken + header.limitWidth - 1;
          long limitEnd = tokenStarts[limitEndToken] + tokenLengths[limitEndToken];
          set(stagedLoops, LOOP_LIMIT_START_ROW + loopCount, limitStart);
          set(stagedLoops, LOOP_LIMIT_LENGTH_ROW + loopCount, limitEnd - limitStart);
          set(
            stagedLoops,
            LOOP_FIRST_BODY_STATEMENT_ROW + loopCount,
            blockFirstStatements[child]
          );
          set(
            stagedLoops,
            LOOP_BODY_STATEMENT_COUNT_ROW + loopCount,
            blockStatementCounts[child]
          );
          set(stagedLoops, LOOP_DEPTH_ROW + loopCount, blockRows[BLOCK_DEPTH_ROW + child]);
          conditionCount += 1;
          loopCount += 1;
        } else {
          valid = false;
        }
      }

      statement += 1;
    }

    if (valid) {
      long row = 0;
      while (row < STATEMENT_ROWS) limit STATEMENT_ROWS {
        set(statementRows, row, stagedStatements[row]);
        row += 1;
      }

      row = 0;
      while (row < CONDITION_ROWS) limit CONDITION_ROWS {
        set(conditionRows, row, stagedConditions[row]);
        row += 1;
      }

      row = 0;
      while (row < LOOP_ROWS) limit LOOP_ROWS {
        set(loopRows, row, stagedLoops[row]);
        row += 1;
      }
    }

    drop(stagedLoops);
    drop(stagedConditions);
    drop(functionOrdinals);
    drop(statementAtTokens);
    drop(statementTokens);
    drop(stagedStatements);
    drop(functionBlockCounts);
    drop(blockUses);
    drop(blockStatementCounts);
    drop(blockFirstStatements);
    drop(blockCloseTokens);
    drop(blockOpenTokens);
    drop(blockParents);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new SourceLoopProductPlan(0, 0, 0, false);
    }

    return new SourceLoopProductPlan(statementCount, conditionCount, loopCount, true);
  }

  /// Merges one five-local frame width for every uniquely joined loop statement.
  public boolean materializeLoopFrameWidths(
    long loopCount,
    borrow mut words loopRows,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementPhysicalWidths
  ) {
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);

    region staging = new region(/* bytes= */ 32768, /* allocations= */ 1);
    words stagedWidths = allocate(staging, MAX_STATEMENTS);
    long statement = 0;
    while (statement < MAX_STATEMENTS) limit MAX_STATEMENTS {
      set(stagedWidths, statement, statementPhysicalWidths[statement]);
      statement += 1;
    }

    boolean valid = true;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long selected = -1;
      long matches = 0;
      statement = 0;
      while (statement < statementCount) limit MAX_STATEMENTS {
        if (statementRows[statement] == loopRows[loop]) {
          if (
            statementRows[STATEMENT_ORDINAL_ROW + statement] == loopRows[LOOP_STATEMENT_ORDINAL_ROW
              + loop]
          ) {
            if (0 < statementRows[STATEMENT_CHILD_COUNT_ROW + statement]) {
              selected = statement;
              matches += 1;
            }
          }
        }

        statement += 1;
      }

      if (matches != 1) {
        valid = false;
      } else {
        set(stagedWidths, selected, 5);
      }

      loop += 1;
    }

    if (valid) {
      statement = 0;
      while (statement < MAX_STATEMENTS) limit MAX_STATEMENTS {
        set(statementPhysicalWidths, statement, stagedWidths[statement]);
        statement += 1;
      }
    }

    drop(stagedWidths);
    drop(staging);
    return valid;
  }
}
