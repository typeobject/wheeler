//! Indexes bounded aggregate construction and projection source ranges.

module wheeler.compiler.closure.source_aggregate_operations;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceAggregateOperations {
  private const long ARGUMENT_ROWS = 4096;
  private const long MAX_ARGUMENTS = 1024;
  private const long MAX_OPERATIONS = 256;
  private const long OPERATION_ROWS = 2048;
  private const long TOKEN_NEW = 108960;
  private const long TOKEN_SLICE = 109526418;

  /// Reports the exact aggregate syntax-product extent.
  public record SourceAggregateOperationPlan(
    long operationCount,
    long argumentCount,
    boolean valid
  ) {}

  private record StagedArguments(long count, boolean valid) {}

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

  private StagedArguments stageArguments(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstToken,
    long closeToken,
    long ownerOperation,
    long argumentCount,
    borrow mut words stagedArguments
  ) {
    long argumentStart = firstToken;
    long argumentIndex = 0;
    long depth = 0;
    long token = firstToken;
    boolean valid = true;
    while (token < closeToken) limit MAX_COMPILER_TOKENS {
      boolean separator = false;
      if (punctuationAt(source, tokenKinds, tokenStarts, token, 40)) {
        depth += 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 91)) {
        depth += 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 123)) {
        depth += 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 41)) {
        depth -= 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 93)) {
        depth -= 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 125)) {
        depth -= 1;
      }

      if (depth < 0) {
        valid = false;
      }

      if (depth == 0) {
        separator = punctuationAt(source, tokenKinds, tokenStarts, token, 44);
      }

      if (separator) {
        if (argumentStart == token) {
          valid = false;
        } else {
          if (argumentCount < MAX_ARGUMENTS) {
            set(stagedArguments, argumentCount, ownerOperation);
            set(stagedArguments, 1024 + argumentCount, argumentIndex);
            set(stagedArguments, 2048 + argumentCount, tokenStarts[argumentStart]);
            set(
              stagedArguments,
              3072 + argumentCount,
              tokenStarts[token] - tokenStarts[argumentStart]
            );
            argumentCount += 1;
            argumentIndex += 1;
          } else {
            valid = false;
          }
        }

        argumentStart = token + 1;
      }

      token += 1;
    }

    if (depth != 0) {
      valid = false;
    }

    if (argumentStart < closeToken) {
      if (argumentCount < MAX_ARGUMENTS) {
        set(stagedArguments, argumentCount, ownerOperation);
        set(stagedArguments, 1024 + argumentCount, argumentIndex);
        set(stagedArguments, 2048 + argumentCount, tokenStarts[argumentStart]);
        set(
          stagedArguments,
          3072 + argumentCount,
          tokenStarts[closeToken] - tokenStarts[argumentStart]
        );
        argumentCount += 1;
      } else {
        valid = false;
      }
    } else {
      if (firstToken < closeToken) {
        valid = false;
      }
    }

    return new StagedArguments(argumentCount, valid);
  }

  /// Publishes sorted syntax ranges only after every aggregate expression is framed.
  public SourceAggregateOperationPlan materializeSourceAggregateOperations(
    borrow utf8 source,
    borrow mut words operationRows,
    borrow mut words argumentRows
  ) {
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(argumentRows) == ARGUMENT_ROWS);
    region scratch = new region(/* bytes= */ 198656, /* allocations= */ 8);
    words tokenKinds = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(scratch, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(scratch, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(scratch, OPERATION_ROWS);
    words stagedArguments = allocate(scratch, ARGUMENT_ROWS);
    words normalizedRows = allocate(scratch, OPERATION_ROWS);
    words normalizedArguments = allocate(scratch, ARGUMENT_ROWS);
    words operationOrder = allocate(scratch, MAX_OPERATIONS);
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
    long argumentCount = 0;
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
            set(stagedRows, 1792 + operationCount, argumentCount);
            StagedArguments constructorArguments = stageArguments(
              source,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              open + 1,
              constructorClose,
              operationCount,
              argumentCount,
              stagedArguments
            );
            argumentCount = constructorArguments.count;
            if (constructorArguments.valid == false) {
              valid = false;
            }

            operationCount += 1;
            cursor += 1;
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
                  set(stagedRows, 1792 + operationCount, argumentCount);
                  StagedArguments sliceArguments = stageArguments(
                    source,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths,
                    cursor + 2,
                    sliceClose,
                    operationCount,
                    argumentCount,
                    stagedArguments
                  );
                  argumentCount = sliceArguments.count;
                  if (sliceArguments.valid == false) {
                    valid = false;
                  }

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
                      set(stagedRows, 1792 + operationCount, argumentCount);
                      operationCount += 1;
                    }
                  }
                }
              }
            }
          }

          if (punctuationAt(source, tokenKinds, tokenStarts, cursor, 91)) {
            if (0 < cursor) {
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
                long indexedSourceStart = -1;
                long indexedSourceLength = 0;
                boolean typeRange = false;
                if (tokenKinds[cursor - 1] == 1) {
                  indexedSourceStart = tokenStarts[cursor - 1];
                  indexedSourceLength = tokenLengths[cursor - 1];
                  if (indexClose + 1 < semanticCount) {
                    typeRange = tokenKinds[indexClose + 1] == 1;
                    if (
                      punctuationAt(source, tokenKinds, tokenStarts, indexClose + 1, 40)
                    ) {
                      typeRange = true;
                    }
                  }
                } else {
                  if (punctuationAt(source, tokenKinds, tokenStarts, cursor - 1, 41)) {
                    long postfixMatchCount = 0;
                    long postfixCandidate = 0;
                    while (postfixCandidate < operationCount) limit MAX_OPERATIONS {
                      long postfixStart = stagedRows[1280 + postfixCandidate];
                      long postfixLength = stagedRows[1536 + postfixCandidate];
                      if (postfixStart + postfixLength == tokenStarts[cursor]) {
                        indexedSourceStart = postfixStart;
                        indexedSourceLength = postfixLength;
                        postfixMatchCount += 1;
                      }

                      postfixCandidate += 1;
                    }

                    if (postfixMatchCount != 1) {
                      valid = false;
                    }
                  }
                }

                if (-1 < indexedSourceStart) {
                  if (typeRange == false) {
                    if (cursor + 1 < indexClose) {
                      assert(operationCount < MAX_OPERATIONS);
                      set(stagedRows, operationCount, 4);
                      set(stagedRows, 256 + operationCount, indexedSourceStart);
                      set(stagedRows, 512 + operationCount, indexedSourceLength);
                      set(stagedRows, 768 + operationCount, tokenStarts[cursor + 1]);
                      set(
                        stagedRows,
                        1024 + operationCount,
                        tokenStarts[indexClose] - tokenStarts[cursor + 1]
                      );
                      set(stagedRows, 1280 + operationCount, indexedSourceStart);
                      set(
                        stagedRows,
                        1536 + operationCount,
                        tokenStarts[indexClose] + tokenLengths[indexClose] - indexedSourceStart
                      );
                      set(stagedRows, 1792 + operationCount, argumentCount);
                      StagedArguments indexArguments = stageArguments(
                        source,
                        tokenKinds,
                        tokenStarts,
                        tokenLengths,
                        cursor + 1,
                        indexClose,
                        operationCount,
                        argumentCount,
                        stagedArguments
                      );
                      argumentCount = indexArguments.count;
                      if (indexArguments.valid == false) {
                        valid = false;
                      }

                      operationCount += 1;
                    } else {
                      valid = false;
                    }
                  }
                }
              }
            }
          }

          cursor += 1;
        }
      }
    }

    long orderedOperation = 0;
    while (orderedOperation < operationCount) limit MAX_OPERATIONS {
      long selectedOperation = -1;
      long selectedEnd = 0;
      long selectedStart = 0;
      long orderingCandidate = 0;
      while (orderingCandidate < operationCount) limit MAX_OPERATIONS {
        if (operationOrder[orderingCandidate] == 0) {
          long candidateStart = stagedRows[1280 + orderingCandidate];
          long candidateEnd = candidateStart + stagedRows[1536 + orderingCandidate];
          boolean selectCandidate = selectedOperation < 0;
          if (-1 < selectedOperation) {
            if (candidateEnd < selectedEnd) {
              selectCandidate = true;
            }

            if (candidateEnd == selectedEnd) {
              if (selectedStart < candidateStart) {
                selectCandidate = true;
              }
            }
          }

          if (selectCandidate) {
            selectedOperation = orderingCandidate;
            selectedEnd = candidateEnd;
            selectedStart = candidateStart;
          }
        }

        orderingCandidate += 1;
      }

      if (selectedOperation < 0) {
        valid = false;
      } else {
        set(operationOrder, selectedOperation, orderedOperation + 1);
        long column = 0;
        while (column < 8) limit 8 {
          set(
            normalizedRows,
            column * 256 + orderedOperation,
            stagedRows[column * 256 + selectedOperation]
          );
          column += 1;
        }
      }

      orderedOperation += 1;
    }

    long normalizedArgumentCount = 0;
    orderedOperation = 0;
    while (orderedOperation < operationCount) limit MAX_OPERATIONS {
      long rawOperation = -1;
      long rawCandidate = 0;
      while (rawCandidate < operationCount) limit MAX_OPERATIONS {
        if (operationOrder[rawCandidate] == orderedOperation + 1) {
          rawOperation = rawCandidate;
        }

        rawCandidate += 1;
      }

      long firstNormalizedArgument = normalizedArgumentCount;
      long expectedArgumentIndex = 0;
      long rawArgument = 0;
      while (rawArgument < argumentCount) limit MAX_ARGUMENTS {
        if (stagedArguments[rawArgument] == rawOperation) {
          if (stagedArguments[1024 + rawArgument] != expectedArgumentIndex) {
            valid = false;
          }

          set(normalizedArguments, normalizedArgumentCount, orderedOperation);
          set(
            normalizedArguments,
            1024 + normalizedArgumentCount,
            stagedArguments[1024 + rawArgument]
          );
          set(
            normalizedArguments,
            2048 + normalizedArgumentCount,
            stagedArguments[2048 + rawArgument]
          );
          set(
            normalizedArguments,
            3072 + normalizedArgumentCount,
            stagedArguments[3072 + rawArgument]
          );
          normalizedArgumentCount += 1;
          expectedArgumentIndex += 1;
        }

        rawArgument += 1;
      }

      set(normalizedRows, 1792 + orderedOperation, firstNormalizedArgument);
      orderedOperation += 1;
    }

    if (normalizedArgumentCount != argumentCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < OPERATION_ROWS) limit OPERATION_ROWS {
        set(operationRows, row, normalizedRows[row]);
        row += 1;
      }

      long argumentRow = 0;
      while (argumentRow < ARGUMENT_ROWS) limit ARGUMENT_ROWS {
        set(argumentRows, argumentRow, normalizedArguments[argumentRow]);
        argumentRow += 1;
      }
    }

    drop(operationOrder);
    drop(normalizedArguments);
    drop(normalizedRows);
    drop(stagedArguments);
    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(scratch);
    return new SourceAggregateOperationPlan(operationCount, argumentCount, valid);
  }
}
