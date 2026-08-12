//! Resolves direct loop-body declarations and updates against callable values.

module wheeler.compiler.closure.resolved_loop_body_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ResolvedLoopBodyProducts {
  private const long BODY_ROWS = 20480;
  private const long BODY_LOCAL_BASE_ROW = 4096;
  private const long BODY_OPCODE_ROW = 8192;
  private const long BODY_OPERAND_KIND_ROW = 12288;
  private const long BODY_OPERAND_ROW = 16384;
  private const long DOCUMENTATION_TOKEN_KIND = 5;
  private const long LINE_COMMENT_TOKEN_KIND = 4;
  private const long MAX_LOCALS = 256;
  private const long MAX_STATEMENTS = 4096;
  private const long OPERAND_LITERAL = 0;
  private const long OPERAND_LOCAL = 1;
  private const long RESOLUTION_ARENA_BYTES = 459776;
  private const long STATEMENT_ROWS = 28672;
  private const long STATEMENT_ORDINAL_ROW = 8192;
  private const long STATEMENT_START_ROW = 12288;
  private const long STATEMENT_LENGTH_ROW = 16384;
  private const long VALUE_COUNT_LIMIT = 1024;
  private const long VALUE_DEFINITION_ORDINAL_ROW = 4096;
  private const long VALUE_LOCAL_ROW = 3072;
  private const long VALUE_NAME_LENGTH_ROW = 2048;
  private const long VALUE_NAME_START_ROW = 1024;
  private const long VALUE_ROWS = 7168;

  /// Reports one complete direct body-statement resolution pass.
  public record ResolvedLoopBodyPlan(long bodyCount, boolean valid) {}

  private record ResolvedValue(long local, boolean valid) {}

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

  private ResolvedValue resolveValue(
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
      return new ResolvedValue(0, false);
    }

    if (selected < 0) {
      return new ResolvedValue(0, false);
    }

    if (MAX_LOCALS - 1 < selected) {
      return new ResolvedValue(0, false);
    }

    return new ResolvedValue(selected, true);
  }

  private long tokenAtStart(long start, long tokenCount, borrow mut words tokenStarts) {
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

  private long localBaseAtOrdinal(
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

  /// Publishes resolved declaration and update rows only after every body statement validates.
  public ResolvedLoopBodyPlan materializeResolvedLoopBodyProducts(
    borrow utf8 source,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words bodyRows
  ) {
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(bodyRows) == BODY_ROWS);

    region staging = new region(/* bytes= */ RESOLUTION_ARENA_BYTES, /* allocations= */ 4);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, BODY_ROWS);
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

    long bodyCount = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (0 < statementRows[4096 + statement]) {
        long owner = statementRows[statement];
        long ordinal = statementRows[STATEMENT_ORDINAL_ROW + statement];
        long start = statementRows[STATEMENT_START_ROW + statement];
        long length = statementRows[STATEMENT_LENGTH_ROW + statement];
        long token = tokenAtStart(start, semanticCount, tokenStarts);
        boolean statementValid = -1 < token;
        if (length < 2) {
          statementValid = false;
        }

        long localBase = localBaseAtOrdinal(owner, ordinal, valueCount, valueRows);
        long opcode = -1;
        long operandKind = OPERAND_LITERAL;
        long operand = 0;
        if (statementValid) {
          if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_LONG) {
            if (tokenKinds[token + 1] != 1) {
              statementValid = false;
            }

            if (
              punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN) == false
            ) {
              statementValid = false;
            }

            if (statementValid) {
              long sourceToken = token + 3;
              if (tokenKinds[sourceToken] == 1) {
                ResolvedValue sourceValue = resolveValue(
                  source,
                  tokenStarts[sourceToken],
                  tokenLengths[sourceToken],
                  owner,
                  ordinal,
                  valueCount,
                  valueRows
                );
                if (sourceValue.valid) {
                  opcode = STATEMENT_LOCAL_LONG_COPY_BASE + sourceValue.local;
                  operandKind = OPERAND_LOCAL;
                  operand = sourceValue.local;
                } else {
                  statementValid = false;
                }
              } else {
                if (
                  signedNumberWidth(source, tokenKinds, tokenStarts, sourceToken) != 1
                ) {
                  statementValid = false;
                } else {
                  if (
                    signedNumberValid(source, tokenStarts, tokenLengths, sourceToken)
                  ) {
                    opcode = 769;
                    operand = parsedSignedNumber(source, tokenStarts, tokenLengths, sourceToken);
                  } else {
                    statementValid = false;
                  }
                }
              }
            }
          } else {
            ResolvedValue target = resolveValue(
              source,
              tokenStarts[token],
              tokenLengths[token],
              owner,
              ordinal,
              valueCount,
              valueRows
            );
            if (target.valid == false) {
              statementValid = false;
            }

            long operation = 0;
            if (
              punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_PLUS)
            ) {
              operation = STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
            }

            if (
              punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_MINUS)
            ) {
              operation = STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
            }

            if (punctuationAt(source, tokenKinds, tokenStarts, token + 1, 94)) {
              operation = STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
            }

            if (operation == 0) {
              statementValid = false;
            }

            if (
              punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN) == false
            ) {
              statementValid = false;
            }

            if (statementValid) {
              long updateSourceToken = token + 3;
              if (tokenKinds[updateSourceToken] == 1) {
                ResolvedValue updateSourceValue = resolveValue(
                  source,
                  tokenStarts[updateSourceToken],
                  tokenLengths[updateSourceToken],
                  owner,
                  ordinal,
                  valueCount,
                  valueRows
                );
                if (updateSourceValue.valid) {
                  opcode = operation + 256 + target.local;
                  operandKind = OPERAND_LOCAL;
                  operand = updateSourceValue.local;
                } else {
                  statementValid = false;
                }
              } else {
                if (
                  signedNumberWidth(source, tokenKinds, tokenStarts, updateSourceToken) != 1
                ) {
                  statementValid = false;
                } else {
                  if (
                    signedNumberValid(source, tokenStarts, tokenLengths, updateSourceToken)
                  ) {
                    opcode = operation + target.local;
                    operand = parsedSignedNumber(
                      source,
                      tokenStarts,
                      tokenLengths,
                      updateSourceToken
                    );
                  } else {
                    statementValid = false;
                  }
                }
              }
            }
          }
        }

        if (statementValid) {
          set(stagedRows, bodyCount, statement);
          set(stagedRows, BODY_LOCAL_BASE_ROW + bodyCount, localBase);
          set(stagedRows, BODY_OPCODE_ROW + bodyCount, opcode);
          set(stagedRows, BODY_OPERAND_KIND_ROW + bodyCount, operandKind);
          set(stagedRows, BODY_OPERAND_ROW + bodyCount, operand);
          bodyCount += 1;
        } else {
          valid = false;
        }
      }

      statement += 1;
    }

    if (valid) {
      long row = 0;
      while (row < BODY_ROWS) limit BODY_ROWS {
        set(bodyRows, row, stagedRows[row]);
        row += 1;
      }
    }

    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new ResolvedLoopBodyPlan(0, false);
    }

    return new ResolvedLoopBodyPlan(bodyCount, true);
  }
}
