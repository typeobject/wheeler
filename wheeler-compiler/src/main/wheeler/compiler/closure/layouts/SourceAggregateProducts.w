//! Parses source-local record and variant products before source release.

module wheeler.compiler.closure.source_aggregate_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceAggregateProducts {
  private const long AGGREGATE_ROWS = 576;
  private const long CASE_ROWS = 640;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_CASES = 128;
  private const long MAX_MEMBERS = 256;
  private const long MEMBER_ROWS = 2048;
  private const long TOKEN_CASE = 3046192;
  private const long TOKEN_RECORD = 3360058449;
  private const long TOKEN_VARIANT = 107610968197;

  /// Reports the exact source-local aggregate, case, and member extents.
  public record SourceAggregateProductPlan(
    long aggregateCount,
    long caseCount,
    long memberCount,
    boolean valid
  ) {}

  private record ParsedMembers(long nextMember, boolean valid) {}

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

  private long rangeHash(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long hash = 0;
    while (cursor < end) limit 256 {
      hash = (hash & TOKEN_HASH_INPUT_MASK) * 31 + utf8Scalar(source, cursor);
      cursor += utf8Width(source, cursor);
    }

    return hash;
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

  private boolean duplicateAggregateName(
    borrow utf8 source,
    long nameStart,
    long nameLength,
    long aggregateCount,
    borrow mut words aggregateRows
  ) {
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      if (
        sameRange(
          source,
          nameStart,
          nameLength,
          aggregateRows[64 + aggregate],
          aggregateRows[128 + aggregate]
        )
      ) {
        return true;
      }

      aggregate += 1;
    }

    return false;
  }

  private boolean duplicateCaseName(
    borrow utf8 source,
    long nameStart,
    long nameLength,
    long firstCase,
    long caseCount,
    borrow mut words caseRows
  ) {
    long nextCase = firstCase;
    while (nextCase < firstCase + caseCount) limit MAX_CASES {
      if (
        sameRange(
          source,
          nameStart,
          nameLength,
          caseRows[128 + nextCase],
          caseRows[256 + nextCase]
        )
      ) {
        return true;
      }

      nextCase += 1;
    }

    return false;
  }

  private ParsedMembers parseMembers(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long open,
    long close,
    long aggregateOwner,
    long caseOwner,
    long memberCount,
    borrow mut words memberRows
  ) {
    long firstMember = memberCount;
    long segmentStart = open + 1;
    long memberCursor = segmentStart;
    boolean valid = true;
    while (valid) limit MAX_COMPILER_TOKENS {
      boolean delimiter = memberCursor == close;
      if (delimiter == false) {
        delimiter = punctuation(source, tokenKinds, tokenStarts, memberCursor, 44);
      }

      if (delimiter) {
        if (segmentStart < memberCursor) {
          if (MAX_MEMBERS < memberCount + 1) {
            valid = false;
          } else {
            long memberNameToken = memberCursor - 1;
            if (segmentStart < memberNameToken) {} else {
              valid = false;
            }

            if (tokenKinds[memberNameToken] != 1) {
              valid = false;
            }

            if (valid) {
              long memberNameStart = tokenStarts[memberNameToken];
              long memberNameLength = tokenLengths[memberNameToken];
              long priorMember = firstMember;
              while (priorMember < memberCount) limit MAX_MEMBERS {
                if (
                  sameRange(
                    source,
                    memberNameStart,
                    memberNameLength,
                    memberRows[512 + priorMember],
                    memberRows[768 + priorMember]
                  )
                ) {
                  valid = false;
                }

                priorMember += 1;
              }

              if (valid) {
                long typeEndToken = memberNameToken - 1;
                long typeStart = tokenStarts[segmentStart];
                long typeEnd = tokenStarts[typeEndToken] + tokenLengths[typeEndToken];
                set(memberRows, memberCount, aggregateOwner);
                set(memberRows, 256 + memberCount, caseOwner);
                set(memberRows, 512 + memberCount, memberNameStart);
                set(memberRows, 768 + memberCount, memberNameLength);
                set(memberRows, 1024 + memberCount, typeStart);
                set(memberRows, 1280 + memberCount, typeEnd - typeStart);
                memberCount += 1;
              }
            }
          }
        } else {
          if (memberCursor != close) {
            valid = false;
          }
        }

        segmentStart = memberCursor + 1;
      }

      if (memberCursor == close) {
        break;
      }

      memberCursor += 1;
    }

    return new ParsedMembers(memberCount, valid);
  }

  private long closingToken(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long tokenCount,
    long opening,
    long closing
  ) {
    long depth = 1;
    long cursor = open + 1;
    while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
      if (punctuation(source, tokenKinds, tokenStarts, cursor, opening)) {
        depth += 1;
      }

      if (punctuation(source, tokenKinds, tokenStarts, cursor, closing)) {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  private long declarationVisibility(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declaration
  ) {
    if (0 < declaration) {
      long modifier = tokenHash(source, tokenStarts, tokenLengths, declaration - 1);
      if (modifier == TOKEN_PUBLIC) {
        return 1;
      }

      if (modifier == TOKEN_PRIVATE) {
        return 0;
      }
    }

    return 0;
  }

  private long primitiveType(long typeHash) {
    if (typeHash == 3327612) {
      return 1;
    }

    if (typeHash == 90259024936) {
      return 2;
    }

    if (typeHash == 3360171764) {
      return 3;
    }

    if (typeHash == 113318569) {
      return 4;
    }

    if (typeHash == 94224491) {
      return 5;
    }

    if (typeHash == 99132996960) {
      return 6;
    }

    if (typeHash == 3600241) {
      return 7;
    }

    if (typeHash == 11018295213) {
      return 13;
    }

    if (typeHash == 2135970) {
      return 14;
    }

    return -1;
  }

  /// Publishes canonical aggregate, case, member, and local-type products atomically.
  public SourceAggregateProductPlan materializeSourceAggregateProducts(
    borrow utf8 source,
    borrow mut words aggregateRows,
    borrow mut words caseRows,
    borrow mut words memberRows
  ) {
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(caseRows) == CASE_ROWS);
    assert(bufferLength(memberRows) == MEMBER_ROWS);
    region scratch = new region(/* bytes= */ 124416, /* allocations= */ 6);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words scratchAggregates = allocate(scratch, AGGREGATE_ROWS);
    words scratchCases = allocate(scratch, CASE_ROWS);
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
    long caseCount = 0;
    long memberCount = 0;
    long cursor = 0;
    while (cursor < semanticCount) limit MAX_COMPILER_TOKENS {
      long declarationKind = tokenHash(source, tokenStarts, tokenLengths, cursor);
      if (declarationKind == TOKEN_RECORD) {
        boolean recordValid = aggregateCount < MAX_AGGREGATES;
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

        long recordClose = -1;
        if (recordValid) {
          recordClose = closingToken(
            source,
            tokenKinds,
            tokenStarts,
            cursor + 2,
            semanticCount,
            40,
            41
          );
          if (recordClose < 0) {
            recordValid = false;
          }
        }

        if (recordValid) {
          if (semanticCount < recordClose + 3) {
            recordValid = false;
          } else {
            if (
              punctuation(source, tokenKinds, tokenStarts, recordClose + 1, 123) == false
            ) {
              recordValid = false;
            }

            if (
              punctuation(source, tokenKinds, tokenStarts, recordClose + 2, 125) == false
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
          if (
            duplicateAggregateName(
              source,
              recordNameStart,
              recordNameLength,
              aggregateCount,
              scratchAggregates
            )
          ) {
            recordValid = false;
          }
        }

        long firstRecordMember = memberCount;
        if (recordValid) {
          ParsedMembers parsedRecord = parseMembers(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            cursor + 2,
            recordClose,
            aggregateCount,
            /* caseOwner= */ -1,
            memberCount,
            scratchMembers
          );
          recordValid = parsedRecord.valid;
          memberCount = parsedRecord.nextMember;
        }

        if (recordValid) {
          set(scratchAggregates, aggregateCount, 1);
          set(scratchAggregates, 64 + aggregateCount, recordNameStart);
          set(scratchAggregates, 128 + aggregateCount, recordNameLength);
          set(scratchAggregates, 192 + aggregateCount, caseCount);
          set(scratchAggregates, 256 + aggregateCount, 0);
          set(scratchAggregates, 320 + aggregateCount, firstRecordMember);
          set(scratchAggregates, 384 + aggregateCount, memberCount - firstRecordMember);
          set(
            scratchAggregates,
            448 + aggregateCount,
            declarationVisibility(source, tokenStarts, tokenLengths, cursor)
          );
          set(scratchAggregates, 512 + aggregateCount, tokenStarts[cursor]);
          aggregateCount += 1;
          cursor = recordClose + 2;
        } else {
          valid = false;
          cursor = semanticCount;
        }
      } else {
        if (declarationKind == TOKEN_VARIANT) {
          boolean variantValid = aggregateCount < MAX_AGGREGATES;
          if (semanticCount < cursor + 5) {
            variantValid = false;
          }

          if (variantValid) {
            if (tokenKinds[cursor + 1] != 1) {
              variantValid = false;
            }

            if (
              punctuation(source, tokenKinds, tokenStarts, cursor + 2, 123) == false
            ) {
              variantValid = false;
            }
          }

          long variantClose = -1;
          if (variantValid) {
            variantClose = closingToken(
              source,
              tokenKinds,
              tokenStarts,
              cursor + 2,
              semanticCount,
              123,
              125
            );
            if (variantClose < 0) {
              variantValid = false;
            }
          }

          long variantNameStart = 0;
          long variantNameLength = 0;
          if (variantValid) {
            variantNameStart = tokenStarts[cursor + 1];
            variantNameLength = tokenLengths[cursor + 1];
            if (
              duplicateAggregateName(
                source,
                variantNameStart,
                variantNameLength,
                aggregateCount,
                scratchAggregates
              )
            ) {
              variantValid = false;
            }
          }

          long firstVariantCase = caseCount;
          long firstVariantMember = memberCount;
          long caseCursor = cursor + 3;
          while (variantValid) limit MAX_CASES {
            if (caseCursor == variantClose) {
              break;
            }

            if (MAX_CASES < caseCount + 1) {
              variantValid = false;
            }

            if (variantClose < caseCursor + 5) {
              variantValid = false;
            }

            if (variantValid) {
              if (
                tokenHash(source, tokenStarts, tokenLengths, caseCursor) != TOKEN_CASE
              ) {
                variantValid = false;
              }

              if (tokenKinds[caseCursor + 1] != 1) {
                variantValid = false;
              }

              if (
                punctuation(source, tokenKinds, tokenStarts, caseCursor + 2, 40) == false
              ) {
                variantValid = false;
              }
            }

            long caseClose = -1;
            if (variantValid) {
              caseClose = closingToken(
                source,
                tokenKinds,
                tokenStarts,
                caseCursor + 2,
                variantClose,
                40,
                41
              );
              if (caseClose < 0) {
                variantValid = false;
              }
            }

            if (variantValid) {
              if (variantClose < caseClose + 2) {
                variantValid = false;
              } else {
                if (
                  punctuation(source, tokenKinds, tokenStarts, caseClose + 1, 59) == false
                ) {
                  variantValid = false;
                }
              }
            }

            long caseNameStart = 0;
            long caseNameLength = 0;
            if (variantValid) {
              caseNameStart = tokenStarts[caseCursor + 1];
              caseNameLength = tokenLengths[caseCursor + 1];
              if (
                duplicateCaseName(
                  source,
                  caseNameStart,
                  caseNameLength,
                  firstVariantCase,
                  caseCount - firstVariantCase,
                  scratchCases
                )
              ) {
                variantValid = false;
              }
            }

            long firstCaseMember = memberCount;
            if (variantValid) {
              ParsedMembers parsedCase = parseMembers(
                source,
                tokenKinds,
                tokenStarts,
                tokenLengths,
                caseCursor + 2,
                caseClose,
                aggregateCount,
                caseCount,
                memberCount,
                scratchMembers
              );
              variantValid = parsedCase.valid;
              memberCount = parsedCase.nextMember;
            }

            if (variantValid) {
              set(scratchCases, caseCount, aggregateCount);
              set(scratchCases, 128 + caseCount, caseNameStart);
              set(scratchCases, 256 + caseCount, caseNameLength);
              set(scratchCases, 384 + caseCount, firstCaseMember);
              set(scratchCases, 512 + caseCount, memberCount - firstCaseMember);
              caseCount += 1;
              caseCursor = caseClose + 2;
            }
          }

          if (variantValid) {
            set(scratchAggregates, aggregateCount, 4);
            set(scratchAggregates, 64 + aggregateCount, variantNameStart);
            set(scratchAggregates, 128 + aggregateCount, variantNameLength);
            set(scratchAggregates, 192 + aggregateCount, firstVariantCase);
            set(scratchAggregates, 256 + aggregateCount, caseCount - firstVariantCase);
            set(scratchAggregates, 320 + aggregateCount, firstVariantMember);
            set(scratchAggregates, 384 + aggregateCount, memberCount - firstVariantMember);
            set(
              scratchAggregates,
              448 + aggregateCount,
              declarationVisibility(source, tokenStarts, tokenLengths, cursor)
            );
            set(scratchAggregates, 512 + aggregateCount, tokenStarts[cursor]);
            aggregateCount += 1;
            cursor = variantClose;
          } else {
            valid = false;
            cursor = semanticCount;
          }
        }
      }

      cursor += 1;
    }

    long resolvedMember = 0;
    while (resolvedMember < memberCount) limit MAX_MEMBERS {
      long resolvedTypeStart = scratchMembers[1024 + resolvedMember];
      long resolvedTypeLength = scratchMembers[1280 + resolvedMember];
      long localTarget = -1;
      long candidateAggregate = 0;
      while (candidateAggregate < aggregateCount) limit MAX_AGGREGATES {
        if (
          sameRange(
            source,
            resolvedTypeStart,
            resolvedTypeLength,
            scratchAggregates[64 + candidateAggregate],
            scratchAggregates[128 + candidateAggregate]
          )
        ) {
          localTarget = candidateAggregate;
        }

        candidateAggregate += 1;
      }

      if (-1 < localTarget) {
        set(scratchMembers, 1536 + resolvedMember, 1);
        set(scratchMembers, 1792 + resolvedMember, localTarget);
      } else {
        long typeHash = rangeHash(source, resolvedTypeStart, resolvedTypeLength);
        long resolvedPrimitive = primitiveType(typeHash);
        if (resolvedPrimitive < 0) {
          valid = false;
        } else {
          set(scratchMembers, 1536 + resolvedMember, 0);
          set(scratchMembers, 1792 + resolvedMember, resolvedPrimitive);
        }
      }

      resolvedMember += 1;
    }

    if (valid) {
      long aggregateRow = 0;
      while (aggregateRow < AGGREGATE_ROWS) limit AGGREGATE_ROWS {
        set(aggregateRows, aggregateRow, scratchAggregates[aggregateRow]);
        aggregateRow += 1;
      }

      long caseRow = 0;
      while (caseRow < CASE_ROWS) limit CASE_ROWS {
        set(caseRows, caseRow, scratchCases[caseRow]);
        caseRow += 1;
      }

      long memberRow = 0;
      while (memberRow < MEMBER_ROWS) limit MEMBER_ROWS {
        set(memberRows, memberRow, scratchMembers[memberRow]);
        memberRow += 1;
      }
    }

    drop(scratchMembers);
    drop(scratchCases);
    drop(scratchAggregates);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return new SourceAggregateProductPlan(aggregateCount, caseCount, memberCount, valid);
  }
}
