//! Indexes source-local nominal type references outside aggregate declarations.

module wheeler.compiler.closure.local_nominal_references;

import wheeler.compiler.closure.source_aggregate_syntax;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class LocalNominalReferences {
  private const long AGGREGATE_ROWS = 832;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_REFERENCES = 512;
  private const long REFERENCE_ROWS = 1536;
  private const long TOKEN_NEW = 108960;

  /// Reports local nominal references in canonical source order.
  public record LocalNominalReferencePlan(long referenceCount, boolean valid) {}

  /// Publishes exact local nominal ranges only after every declaration range validates.
  public LocalNominalReferencePlan materializeLocalNominalReferences(
    borrow utf8 source,
    long aggregateCount,
    borrow mut words aggregateRows,
    borrow mut words referenceRows
  ) {
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(referenceRows) == REFERENCE_ROWS);
    boolean valid = true;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long kind = aggregateRows[aggregate];
      if (kind == 1) {
        long declarationStart = aggregateRows[512 + aggregate];
        long declarationEnd = aggregateRows[768 + aggregate];
        if (declarationStart < 0) {
          valid = false;
        }

        if (declarationEnd < declarationStart + 1) {
          valid = false;
        }

        if (bufferLength(source) < declarationEnd) {
          valid = false;
        }
      }

      if (kind == 4) {
        long variantDeclarationStart = aggregateRows[512 + aggregate];
        long variantDeclarationEnd = aggregateRows[768 + aggregate];
        if (variantDeclarationStart < 0) {
          valid = false;
        }

        if (variantDeclarationEnd < variantDeclarationStart + 1) {
          valid = false;
        }

        if (bufferLength(source) < variantDeclarationEnd) {
          valid = false;
        }
      }

      aggregate += 1;
    }

    if (valid == false) {
      return new LocalNominalReferencePlan(0, false);
    }

    region scratch = new region(/* bytes= */ 110592, /* allocations= */ 4);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words stagedReferences = allocate(scratch, REFERENCE_ROWS);
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
      long tokenKind = tokenKinds[readToken];
      if (tokenKind != 4) {
        if (tokenKind != 5) {
          set(tokenKinds, semanticCount, tokenKind);
          set(tokenStarts, semanticCount, tokenStarts[readToken]);
          set(tokenLengths, semanticCount, tokenLengths[readToken]);
          semanticCount += 1;
        }
      }

      readToken += 1;
    }

    long referenceCount = 0;
    long token = 0;
    while (token < semanticCount) limit MAX_COMPILER_TOKENS {
      if (tokenKinds[token] == 1) {
        boolean typePosition = false;
        if (token + 1 < semanticCount) {
          typePosition = tokenKinds[token + 1] == 1;
        }

        if (0 < token) {
          if (tokenHash(source, tokenStarts, tokenLengths, token - 1) == TOKEN_NEW) {
            typePosition = true;
          }
        }

        if (typePosition) {
          long tokenStart = tokenStarts[token];
          boolean declarationToken = false;
          aggregate = 0;
          while (aggregate < aggregateCount) limit MAX_AGGREGATES {
            long aggregateKind = aggregateRows[aggregate];
            if (aggregateKind == 1) {
              if (aggregateRows[512 + aggregate] < tokenStart + 1) {
                if (tokenStart < aggregateRows[768 + aggregate]) {
                  declarationToken = true;
                }
              }
            }

            if (aggregateKind == 4) {
              if (aggregateRows[512 + aggregate] < tokenStart + 1) {
                if (tokenStart < aggregateRows[768 + aggregate]) {
                  declarationToken = true;
                }
              }
            }

            aggregate += 1;
          }

          if (declarationToken == false) {
            long selected = -1;
            long matches = 0;
            aggregate = 0;
            while (aggregate < aggregateCount) limit MAX_AGGREGATES {
              long candidateKind = aggregateRows[aggregate];
              if (candidateKind == 1) {
                if (
                  sameRange(
                    source,
                    tokenStart,
                    tokenLengths[token],
                    aggregateRows[64 + aggregate],
                    aggregateRows[128 + aggregate]
                  )
                ) {
                  selected = aggregate;
                  matches += 1;
                }
              }

              if (candidateKind == 4) {
                if (
                  sameRange(
                    source,
                    tokenStart,
                    tokenLengths[token],
                    aggregateRows[64 + aggregate],
                    aggregateRows[128 + aggregate]
                  )
                ) {
                  selected = aggregate;
                  matches += 1;
                }
              }

              aggregate += 1;
            }

            if (1 < matches) {
              valid = false;
            }

            if (matches == 1) {
              if (referenceCount < MAX_REFERENCES) {
                set(stagedReferences, referenceCount, selected);
                set(stagedReferences, 512 + referenceCount, tokenStart);
                set(stagedReferences, 1024 + referenceCount, tokenLengths[token]);
                referenceCount += 1;
              } else {
                valid = false;
              }
            }
          }
        }
      }

      token += 1;
    }

    if (valid) {
      long row = 0;
      while (row < REFERENCE_ROWS) limit REFERENCE_ROWS {
        set(referenceRows, row, stagedReferences[row]);
        row += 1;
      }
    }

    drop(stagedReferences);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return new LocalNominalReferencePlan(referenceCount, valid);
  }
}
