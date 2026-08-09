//! Indexes bounded aggregate construction and projection source ranges.

module wheeler.compiler.closure.source_aggregate_operations;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceAggregateOperations {
  private const long MAX_OPERATIONS = 256;
  private const long OPERATION_ROWS = 2048;
  private const long TOKEN_NEW = 108960;
  private const long TOKEN_SLICE = 109526418;

  /// Reports the exact aggregate syntax-product extent.
  public record SourceAggregateOperationPlan(long operationCount, boolean valid) {}

  private long closingToken(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long tokenCount,
    long opening,
    long closing
  ) {
    long depth = 0;
    long token = open;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (punctuationAt(source, tokenKinds, tokenStarts, token, opening)) {
        depth += 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, closing)) {
        depth -= 1;
        if (depth == 0) {
          return token;
        }
      }

      token += 1;
    }

    return -1;
  }

  /// Publishes sorted syntax ranges only after every aggregate expression is framed.
  public SourceAggregateOperationPlan materializeSourceAggregateOperations(
    borrow utf8 source,
    borrow mut words operationRows
  ) {
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    region scratch = new region(/* bytes= */ 114688, /* allocations= */ 4);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(scratch, OPERATION_ROWS);
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

    long operationCount = 0;
    long cursor = 0;
    while (cursor < semanticCount) limit MAX_COMPILER_TOKENS {
      long hash = tokenHash(source, tokenStarts, tokenLengths, cursor);
      if (hash == TOKEN_NEW) {
        boolean framed = cursor + 2 < semanticCount;
        long typeStart = 0;
        long typeLength = 0;
        long selectorStart = -1;
        long selectorLength = 0;
        long open = -1;
        if (framed) {
          framed = tokenKinds[cursor + 1] == 1;
          typeStart = tokenStarts[cursor + 1];
          typeLength = tokenLengths[cursor + 1];
          open = cursor + 2;
        }

        if (framed) {
          if (punctuationAt(source, tokenKinds, tokenStarts, open, 91)) {
            long typeClose = closingToken(
              source,
              tokenKinds,
              tokenStarts,
              open,
              semanticCount,
              91,
              93
            );
            if (typeClose < 0) {
              framed = false;
            } else {
              typeLength = tokenStarts[typeClose] + tokenLengths[typeClose] - typeStart;
              open = typeClose + 1;
            }
          }
        }

        if (framed) {
          if (punctuationAt(source, tokenKinds, tokenStarts, open, 46)) {
            if (open + 2 < semanticCount) {
              if (tokenKinds[open + 1] == 1) {
                selectorStart = tokenStarts[open + 1];
                selectorLength = tokenLengths[open + 1];
                open += 2;
              } else {
                framed = false;
              }
            } else {
              framed = false;
            }
          }
        }

        if (framed) {
          framed = punctuationAt(source, tokenKinds, tokenStarts, open, 40);
        }

        long constructorClose = -1;
        if (framed) {
          constructorClose = closingToken(
            source,
            tokenKinds,
            tokenStarts,
            open,
            semanticCount,
            40,
            41
          );
          if (constructorClose < 0) {
            framed = false;
          }
        }

        if (framed == false) {
          valid = false;
          cursor = semanticCount;
        } else {
          if (operationCount < MAX_OPERATIONS) {} else {
            valid = false;
            cursor = semanticCount;
          }

          if (valid) {
            long operationKind = 1;
            if (-1 < selectorStart) {
              operationKind = 2;
            }

            set(stagedRows, operationCount, operationKind);
            set(stagedRows, 256 + operationCount, typeStart);
            set(stagedRows, 512 + operationCount, typeLength);
            set(stagedRows, 768 + operationCount, selectorStart);
            set(stagedRows, 1024 + operationCount, selectorLength);
            set(stagedRows, 1280 + operationCount, tokenStarts[cursor]);
            set(
              stagedRows,
              1536 + operationCount,
              tokenStarts[constructorClose] + tokenLengths[constructorClose] - tokenStarts[cursor]
            );
            operationCount += 1;
            cursor = constructorClose + 1;
          }
        }
      } else {
        if (hash == TOKEN_SLICE) {
          if (cursor + 1 < semanticCount) {
            if (punctuationAt(source, tokenKinds, tokenStarts, cursor + 1, 40)) {
              long sliceClose = closingToken(
                source,
                tokenKinds,
                tokenStarts,
                cursor + 1,
                semanticCount,
                40,
                41
              );
              if (sliceClose < 0) {
                valid = false;
                cursor = semanticCount;
              } else {
                if (operationCount < MAX_OPERATIONS) {} else {
                  valid = false;
                  cursor = semanticCount;
                }

                if (valid) {
                  set(stagedRows, operationCount, 5);
                  set(stagedRows, 256 + operationCount, tokenStarts[cursor]);
                  set(stagedRows, 512 + operationCount, tokenLengths[cursor]);
                  set(stagedRows, 768 + operationCount, -1);
                  set(stagedRows, 1280 + operationCount, tokenStarts[cursor]);
                  set(
                    stagedRows,
                    1536 + operationCount,
                    tokenStarts[sliceClose] + tokenLengths[sliceClose] - tokenStarts[cursor]
                  );
                  operationCount += 1;
                  cursor += 1;
                }
              }
            }
          }
        }

        if (valid) {
          if (punctuationAt(source, tokenKinds, tokenStarts, cursor, 46)) {
            if (0 < cursor) {
              if (cursor + 1 < semanticCount) {
                if (tokenKinds[cursor - 1] == 1) {
                  if (tokenKinds[cursor + 1] == 1) {
                    boolean call = false;
                    if (cursor + 2 < semanticCount) {
                      call = punctuationAt(source, tokenKinds, tokenStarts, cursor + 2, 40);
                    }

                    if (call == false) {
                      assert(operationCount < MAX_OPERATIONS);
                      set(stagedRows, operationCount, 3);
                      set(stagedRows, 256 + operationCount, tokenStarts[cursor - 1]);
                      set(stagedRows, 512 + operationCount, tokenLengths[cursor - 1]);
                      set(stagedRows, 768 + operationCount, tokenStarts[cursor + 1]);
                      set(stagedRows, 1024 + operationCount, tokenLengths[cursor + 1]);
                      set(stagedRows, 1280 + operationCount, tokenStarts[cursor - 1]);
                      set(
                        stagedRows,
                        1536 + operationCount,
                        tokenStarts[cursor + 1] + tokenLengths[cursor + 1] - tokenStarts[cursor - 1]
                      );
                      operationCount += 1;
                    }
                  }
                }
              }
            }
          }

          if (punctuationAt(source, tokenKinds, tokenStarts, cursor, 91)) {
            if (0 < cursor) {
              if (tokenKinds[cursor - 1] == 1) {
                long indexClose = closingToken(
                  source,
                  tokenKinds,
                  tokenStarts,
                  cursor,
                  semanticCount,
                  91,
                  93
                );
                if (indexClose < 0) {
                  valid = false;
                  cursor = semanticCount;
                } else {
                  boolean typeRange = false;
                  if (indexClose + 1 < semanticCount) {
                    typeRange = tokenKinds[indexClose + 1] == 1;
                  }

                  if (typeRange == false) {
                    assert(operationCount < MAX_OPERATIONS);
                    set(stagedRows, operationCount, 4);
                    set(stagedRows, 256 + operationCount, tokenStarts[cursor - 1]);
                    set(stagedRows, 512 + operationCount, tokenLengths[cursor - 1]);
                    set(stagedRows, 768 + operationCount, tokenStarts[cursor + 1]);
                    set(
                      stagedRows,
                      1024 + operationCount,
                      tokenStarts[indexClose] - tokenStarts[cursor + 1]
                    );
                    set(stagedRows, 1280 + operationCount, tokenStarts[cursor - 1]);
                    set(
                      stagedRows,
                      1536 + operationCount,
                      tokenStarts[indexClose] + tokenLengths[indexClose] - tokenStarts[cursor - 1]
                    );
                    operationCount += 1;
                  }

                  cursor = indexClose;
                }
              }
            }
          }

          cursor += 1;
        }
      }
    }

    if (valid) {
      long row = 0;
      while (row < OPERATION_ROWS) limit OPERATION_ROWS {
        set(operationRows, row, stagedRows[row]);
        row += 1;
      }
    }

    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return new SourceAggregateOperationPlan(operationCount, valid);
  }
}
