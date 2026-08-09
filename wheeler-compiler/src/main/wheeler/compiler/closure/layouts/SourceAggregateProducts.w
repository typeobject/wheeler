//! Parses source-local record declarations before the source lease is released.

module wheeler.compiler.closure.source_aggregate_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceAggregateProducts {
  private const long AGGREGATE_ROWS = 384;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_MEMBERS = 256;
  private const long MEMBER_ROWS = 1280;
  private const long TOKEN_RECORD = 3360058449;

  /// Reports the exact source-local record and member product extents.
  public record SourceAggregateProductPlan(long aggregateCount, long memberCount, boolean valid) {}

  private boolean punctuation(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long expected
  ) {
    if (tokenKinds[token] != 3) {
      return false;
    }

    return utf8Scalar(source, tokenStarts[token]) == expected;
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

      offset += utf8Width(source, leftStart + offset);
    }

    return true;
  }

  /// Publishes canonical record names, member names, and member type ranges atomically.
  public SourceAggregateProductPlan materializeSourceRecordProducts(
    borrow utf8 source,
    borrow mut words aggregateRows,
    borrow mut words memberRows
  ) {
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(memberRows) == MEMBER_ROWS);
    region scratch = new region(/* bytes= */ 111616, /* allocations= */ 5);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words scratchAggregates = allocate(scratch, AGGREGATE_ROWS);
    words scratchMembers = allocate(scratch, MEMBER_ROWS);

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

    long aggregateCount = 0;
    long memberCount = 0;
    long cursor = 0;
    while (cursor < semanticCount) limit MAX_COMPILER_TOKENS {
      boolean recordStarts = tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_RECORD;
      if (recordStarts) {
        boolean recordValid = true;
        if (MAX_AGGREGATES < aggregateCount + 1) {
          recordValid = false;
        }

        if (semanticCount < cursor + 6) {
          recordValid = false;
        }

        if (recordValid) {
          if (tokenKinds[cursor + 1] != 1) {
            recordValid = false;
          }

          if (punctuation(source, tokenKinds, tokenStarts, cursor + 2, 40) == false) {
            recordValid = false;
          }
        }

        long close = cursor + 2;
        if (recordValid) {
          long depth = 1;
          close += 1;
          while (close < semanticCount) limit MAX_COMPILER_TOKENS {
            if (punctuation(source, tokenKinds, tokenStarts, close, 40)) {
              depth += 1;
            }

            if (punctuation(source, tokenKinds, tokenStarts, close, 41)) {
              depth -= 1;
              if (depth == 0) {
                break;
              }
            }

            close += 1;
          }

          if (depth != 0) {
            recordValid = false;
          }
        }

        if (recordValid) {
          if (semanticCount < close + 3) {
            recordValid = false;
          } else {
            if (
              punctuation(source, tokenKinds, tokenStarts, close + 1, 123) == false
            ) {
              recordValid = false;
            }

            if (
              punctuation(source, tokenKinds, tokenStarts, close + 2, 125) == false
            ) {
              recordValid = false;
            }
          }
        }

        long recordNameStart = 0;
        long recordNameLength = 0;
        if (recordValid) {
          recordNameStart = tokenStarts[cursor + 1];
          recordNameLength = tokenLengths[cursor + 1];
          long previousAggregate = 0;
          while (previousAggregate < aggregateCount) limit MAX_AGGREGATES {
            if (
              sameRange(
                source,
                recordNameStart,
                recordNameLength,
                scratchAggregates[previousAggregate],
                scratchAggregates[64 + previousAggregate]
              )
            ) {
              recordValid = false;
            }

            previousAggregate += 1;
          }
        }

        long firstMember = memberCount;
        long segmentStart = cursor + 3;
        long memberCursor = segmentStart;
        while (recordValid) limit MAX_COMPILER_TOKENS {
          boolean delimiter = memberCursor == close;
          if (delimiter == false) {
            delimiter = punctuation(source, tokenKinds, tokenStarts, memberCursor, 44);
          }

          if (delimiter) {
            if (segmentStart < memberCursor) {
              if (MAX_MEMBERS < memberCount + 1) {
                recordValid = false;
              } else {
                long memberNameToken = memberCursor - 1;
                if (segmentStart < memberNameToken) {} else {
                  recordValid = false;
                }

                if (tokenKinds[memberNameToken] != 1) {
                  recordValid = false;
                }

                if (recordValid) {
                  long memberNameStart = tokenStarts[memberNameToken];
                  long memberNameLength = tokenLengths[memberNameToken];
                  long priorMember = firstMember;
                  while (priorMember < memberCount) limit MAX_MEMBERS {
                    if (
                      sameRange(
                        source,
                        memberNameStart,
                        memberNameLength,
                        scratchMembers[256 + priorMember],
                        scratchMembers[512 + priorMember]
                      )
                    ) {
                      recordValid = false;
                    }

                    priorMember += 1;
                  }

                  if (recordValid) {
                    long typeEndToken = memberNameToken - 1;
                    long typeStart = tokenStarts[segmentStart];
                    long typeEnd = tokenStarts[typeEndToken] + tokenLengths[typeEndToken];
                    set(scratchMembers, memberCount, aggregateCount);
                    set(scratchMembers, 256 + memberCount, memberNameStart);
                    set(scratchMembers, 512 + memberCount, memberNameLength);
                    set(scratchMembers, 768 + memberCount, typeStart);
                    set(scratchMembers, 1024 + memberCount, typeEnd - typeStart);
                    memberCount += 1;
                  }
                }
              }
            } else {
              if (memberCursor != close) {
                recordValid = false;
              }
            }

            segmentStart = memberCursor + 1;
          }

          if (memberCursor == close) {
            break;
          }

          memberCursor += 1;
        }

        if (recordValid) {
          long visibility = 0;
          if (0 < cursor) {
            long modifier = tokenHash(source, tokenStarts, tokenLengths, cursor - 1);
            if (modifier == TOKEN_PUBLIC) {
              visibility = 1;
            }

            if (modifier == TOKEN_PRIVATE) {
              visibility = 0;
            }
          }

          set(scratchAggregates, aggregateCount, recordNameStart);
          set(scratchAggregates, 64 + aggregateCount, recordNameLength);
          set(scratchAggregates, 128 + aggregateCount, firstMember);
          set(scratchAggregates, 192 + aggregateCount, memberCount - firstMember);
          set(scratchAggregates, 256 + aggregateCount, visibility);
          set(scratchAggregates, 320 + aggregateCount, tokenStarts[cursor]);
          aggregateCount += 1;
          cursor = close + 2;
        } else {
          valid = false;
          cursor = semanticCount;
        }
      }

      cursor += 1;
    }

    if (valid) {
      long aggregateRow = 0;
      while (aggregateRow < AGGREGATE_ROWS) limit AGGREGATE_ROWS {
        set(aggregateRows, aggregateRow, scratchAggregates[aggregateRow]);
        aggregateRow += 1;
      }

      long memberRow = 0;
      while (memberRow < MEMBER_ROWS) limit MEMBER_ROWS {
        set(memberRows, memberRow, scratchMembers[memberRow]);
        memberRow += 1;
      }
    }

    drop(scratchMembers);
    drop(scratchAggregates);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return new SourceAggregateProductPlan(aggregateCount, memberCount, valid);
  }
}
