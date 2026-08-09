//! Parses source-local record and variant products before source release.

module wheeler.compiler.closure.source_aggregate_products;

import wheeler.compiler.closure.aggregate_operand_projections;
import wheeler.compiler.closure.aggregate_owner_projections;
import wheeler.compiler.closure.imported_nominal_products;
import wheeler.compiler.closure.imported_nominal_stubs;
import wheeler.compiler.closure.source_aggregate_layouts;
import wheeler.compiler.closure.source_aggregate_syntax;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceAggregateProducts {
  private const long AGGREGATE_ROWS = 832;
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
    region scratch = new region(/* bytes= */ 126464, /* allocations= */ 6);
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
          set(
            scratchAggregates,
            512 + aggregateCount,
            declarationStart(source, tokenStarts, tokenLengths, cursor)
          );
          set(
            scratchAggregates,
            768 + aggregateCount,
            tokenStarts[recordClose + 2] + tokenLengths[recordClose + 2]
          );
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
            set(
              scratchAggregates,
              512 + aggregateCount,
              declarationStart(source, tokenStarts, tokenLengths, cursor)
            );
            set(
              scratchAggregates,
              768 + aggregateCount,
              tokenStarts[variantClose] + tokenLengths[variantClose]
            );
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
        StructuralType structure = structuralType(source, resolvedTypeStart, resolvedTypeLength);
        if (structure.applies) {
          boolean structuralUsable = structure.valid;
          if (structuralUsable == false) {
            valid = false;
          }

          if (structure.kind == 3) {
            structuralUsable = false;
            valid = false;
          }

          long structuralTarget = -1;
          long structuralCandidate = 0;
          while (structuralCandidate < aggregateCount) limit MAX_AGGREGATES {
            if (scratchAggregates[structuralCandidate] == structure.kind) {
              if (
                sameRange(
                  source,
                  resolvedTypeStart,
                  resolvedTypeLength,
                  scratchAggregates[64 + structuralCandidate],
                  scratchAggregates[128 + structuralCandidate]
                )
              ) {
                structuralTarget = structuralCandidate;
              }
            }

            structuralCandidate += 1;
          }

          if (structuralUsable) {
            if (structuralTarget < 0) {
              if (MAX_AGGREGATES < aggregateCount + 1) {
                valid = false;
              } else {
                structuralTarget = aggregateCount;
                set(scratchAggregates, aggregateCount, structure.kind);
                set(scratchAggregates, 64 + aggregateCount, resolvedTypeStart);
                set(scratchAggregates, 128 + aggregateCount, resolvedTypeLength);
                set(scratchAggregates, 192 + aggregateCount, caseCount);
                set(scratchAggregates, 256 + aggregateCount, 0);
                set(scratchAggregates, 320 + aggregateCount, memberCount);
                set(scratchAggregates, 384 + aggregateCount, 0);
                set(scratchAggregates, 448 + aggregateCount, 0);
                set(scratchAggregates, 512 + aggregateCount, resolvedTypeStart);
                set(scratchAggregates, 576 + aggregateCount, 0);
                set(scratchAggregates, 640 + aggregateCount, structure.element);
                set(scratchAggregates, 704 + aggregateCount, structure.length);
                set(
                  scratchAggregates,
                  768 + aggregateCount,
                  resolvedTypeStart + resolvedTypeLength
                );
                aggregateCount += 1;
              }
            }

            if (-1 < structuralTarget) {
              set(scratchMembers, 1536 + resolvedMember, 1);
              set(scratchMembers, 1792 + resolvedMember, structuralTarget);
            }
          }
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
