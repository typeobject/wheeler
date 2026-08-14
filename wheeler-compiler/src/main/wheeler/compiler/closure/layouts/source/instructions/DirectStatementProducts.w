//! Emits canonical code and local types for source-local root statements.

module wheeler.compiler.closure.direct_statement_products;

import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;
import wheeler.lexer.scanner;

classical class DirectStatementProducts {
  private const long DIRECT_ROWS = 28672;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_STATEMENTS = 4096;
  private const long TYPE_ROWS = 12288;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one complete direct code and local-type product set.
  public record DirectStatementPlan(
    long productCount,
    long instructionCount,
    long length,
    long typeCount,
    boolean valid
  ) {}

  private long statementAtOrdinal(
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] == ordinal) {
          selected = statement;
          matches += 1;
        }
      }

      statement += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long physicalValueLocal(
    long owner,
    long local,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementPhysicalStarts
  ) {
    long value = 0;
    long selected = -1;
    long matches = 0;
    while (value < valueCount) limit LOOP_VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[3072 + value] == local) {
          selected = value;
          matches += 1;
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return -1;
    }

    long ordinal = valueRows[4096 + selected];
    if (ordinal == 0) {
      return local;
    }

    long statement = statementAtOrdinal(owner, ordinal, statementCount, statementRows);
    if (statement < 0) {
      return -1;
    }

    long logicalBase = statementLocalRows[statement];
    if (local < logicalBase) {
      return -1;
    }

    return statementPhysicalStarts[statement] + local - logicalBase;
  }

  private long physicalAssertionOpcode(
    long opcode,
    long owner,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementPhysicalStarts
  ) {
    long base = -1;
    if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_LITERAL) {
        base = opcode / 256 * 256;
      }
    }

    if (BODY_ASSERT_LITERAL_LT_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LOCAL_LT_BASE + 256) {
        base = opcode / 256 * 256;
      }
    }

    if (base < 0) {
      return opcode;
    }

    long physical = physicalValueLocal(
      owner,
      opcode - base,
      statementCount,
      statementRows,
      statementLocalRows,
      valueCount,
      valueRows,
      statementPhysicalStarts
    );
    if (physical < 0) {
      return -1;
    }

    return base + physical;
  }

  /// Emits literal and prior-local declarations plus local returns in source order.
  public DirectStatementPlan materializeDirectStatementProducts(
    borrow utf8 source,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    borrow mut words statementPhysicalWidths,
    borrow mut words directRows,
    borrow mut words typeRows,
    borrow mut bytes output
  ) {
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < LOOP_VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == LOOP_VALUE_ROWS);
    assert(bufferLength(statementLocalRows) == 8192);
    assert(bufferLength(statementPhysicalStarts) == MAX_STATEMENTS);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);
    assert(bufferLength(directRows) == DIRECT_ROWS);
    assert(bufferLength(typeRows) == TYPE_ROWS);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ 884736, /* allocations= */ 8);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, DIRECT_ROWS);
    words assertionBody = allocate(staging, BODY_ROWS);
    words stagedTypes = allocate(staging, TYPE_ROWS);
    words stagedPhysicalWidths = allocate(staging, MAX_STATEMENTS);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    long stagedStatement = 0;
    while (stagedStatement < MAX_STATEMENTS) limit MAX_STATEMENTS {
      set(stagedPhysicalWidths, stagedStatement, statementPhysicalWidths[stagedStatement]);
      stagedStatement += 1;
    }

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

    long semanticCount = compactLoopBodyTokens(
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );
    long cursor = 0;
    long productCount = 0;
    long instructionCount = 0;
    long typeCount = 0;
    long priorStart = -1;
    long processed = 0;
    while (processed < statementCount) limit MAX_STATEMENTS {
      long statement = nextLoopBodyStatement(
        priorStart,
        statementCount,
        statementRows,
        LOOP_STATEMENT_START_ROW
      );
      if (statement == statementCount) {
        valid = false;
      } else {
        priorStart = statementRows[LOOP_STATEMENT_START_ROW + statement];
        long owner = statementRows[statement];
        long rootBlock = loopBodyRootBlockForOwner(owner, statementCount, statementRows);
        if (statementRows[4096 + statement] == rootBlock) {
          if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement] == 0) {
            long physicalStatementBase = statementPhysicalStarts[statement];
            long token = tokenAtStart(
              statementRows[LOOP_STATEMENT_START_ROW + statement],
              semanticCount,
              tokenStarts
            );
            boolean statementValid = -1 < token;
            long productStart = cursor;
            long productInstructions = 0;
            long productTypeStart = typeCount;
            long hash = 0;
            if (statementValid) {
              hash = tokenHash(source, tokenStarts, tokenLengths, token);
            }

            if (hash == TOKEN_LONG) {
              LoopBodyValue destination = resolveLoopBodyValue(
                source,
                tokenStarts[token + 1],
                tokenLengths[token + 1],
                owner,
                statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] + 1,
                valueCount,
                valueRows
              );
              if (destination.valid == false) {
                statementValid = false;
              }

              long localBase = physicalStatementBase;
              long destinationLocal = localBase + 1;
              long sourceToken = token + 3;
              long sourceOpcode = OPCODE_LOCAL_CONST;
              long sourceOperand = 0;
              if (tokenKinds[sourceToken] == 1) {
                LoopBodyValue sourceValue = resolveLoopBodyValue(
                  source,
                  tokenStarts[sourceToken],
                  tokenLengths[sourceToken],
                  owner,
                  statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement],
                  valueCount,
                  valueRows
                );
                if (sourceValue.valid) {
                  if (
                    signedLoopBodyLocal(
                      source,
                      owner,
                      sourceValue.local,
                      valueCount,
                      valueRows,
                      semanticCount,
                      tokenStarts,
                      tokenLengths
                    )
                  ) {
                    sourceOpcode = OPCODE_LOCAL_MOVE;
                    sourceOperand = physicalValueLocal(
                      owner,
                      sourceValue.local,
                      statementCount,
                      statementRows,
                      statementLocalRows,
                      valueCount,
                      valueRows,
                      statementPhysicalStarts
                    );
                    if (sourceOperand < 0) {
                      statementValid = false;
                    }
                  } else {
                    statementValid = false;
                  }
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
                    sourceOperand = parsedSignedNumber(
                      source,
                      tokenStarts,
                      tokenLengths,
                      sourceToken
                    );
                  } else {
                    statementValid = false;
                  }
                }
              }

              if (statementValid) {
                cursor = writeInstructionHeader(
                  stagedCode,
                  cursor,
                  sourceOpcode,
                  INSTRUCTION_FORM_BINARY
                );
                cursor = writeUnsignedLittleEndian(stagedCode, cursor, localBase, U64);
                if (sourceOpcode == OPCODE_LOCAL_MOVE) {
                  cursor = writeUnsignedLittleEndian(stagedCode, cursor, sourceOperand, U64);
                } else {
                  cursor = writeSignedLittleEndian(stagedCode, cursor, sourceOperand, U64);
                }

                cursor = writeInstructionHeader(
                  stagedCode,
                  cursor,
                  OPCODE_LOCAL_MOVE,
                  INSTRUCTION_FORM_BINARY
                );
                cursor = writeUnsignedLittleEndian(stagedCode, cursor, destinationLocal, U64);
                cursor = writeUnsignedLittleEndian(stagedCode, cursor, localBase, U64);
                set(stagedTypes, typeCount, owner);
                set(stagedTypes, 4096 + typeCount, localBase);
                set(stagedTypes, 8192 + typeCount, TYPE_SIGNED);
                typeCount += 1;
                set(stagedTypes, typeCount, owner);
                set(stagedTypes, 4096 + typeCount, destinationLocal);
                set(stagedTypes, 8192 + typeCount, TYPE_SIGNED);
                typeCount += 1;
                productInstructions = 2;
              }
            } else {
              if (hash == TOKEN_ASSERT) {
                long ordinal = statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement];
                LoopAssertion assertion = resolveLoopAssertion(
                  source,
                  token,
                  owner,
                  ordinal,
                  valueCount,
                  valueRows,
                  semanticCount,
                  tokenKinds,
                  tokenStarts,
                  tokenLengths
                );
                if (assertion.valid == false) {
                  statementValid = false;
                }

                long assertionLocalBase = physicalStatementBase;
                long assertionOpcode = physicalAssertionOpcode(
                  assertion.opcode,
                  owner,
                  statementCount,
                  statementRows,
                  statementLocalRows,
                  valueCount,
                  valueRows,
                  statementPhysicalStarts
                );
                if (assertionOpcode < 0) {
                  statementValid = false;
                }

                long assertionOperand = assertion.operand;
                if (assertion.operandKind == 1) {
                  assertionOperand = physicalValueLocal(
                    owner,
                    assertion.operand,
                    statementCount,
                    statementRows,
                    statementLocalRows,
                    valueCount,
                    valueRows,
                    statementPhysicalStarts
                  );
                  if (assertionOperand < 0) {
                    statementValid = false;
                  }
                }

                if (statementValid) {
                  set(assertionBody, BODY_LOCAL_BASE_ROW, assertionLocalBase);
                  set(assertionBody, BODY_OPCODE_ROW, assertionOpcode);
                  set(assertionBody, BODY_OPERAND_KIND_ROW, assertion.operandKind);
                  set(assertionBody, BODY_OPERAND_ROW, assertionOperand);
                  long next = writeLoopBodyInstructionProduct(
                    stagedCode,
                    cursor,
                    /* body= */ 0,
                    assertionBody
                  );
                  if (next < 0) {
                    statementValid = false;
                  } else {
                    long localCount = loopBodyLocalCount(assertion.opcode, assertion.operand);
                    if (localCount < 1) {
                      statementValid = false;
                    } else {
                      long localOffset = 0;
                      while (localOffset < localCount) limit 3 {
                        long localType = TYPE_SIGNED;
                        if (localOffset == localCount - 1) {
                          localType = TYPE_BOOLEAN;
                        }

                        if (assertion.opcode == BODY_ASSERT_BOOLEAN) {
                          localType = TYPE_BOOLEAN;
                        }

                        set(stagedTypes, typeCount, owner);
                        set(stagedTypes, 4096 + typeCount, assertionLocalBase + localOffset);
                        set(stagedTypes, 8192 + typeCount, localType);
                        typeCount += 1;
                        localOffset += 1;
                      }

                      cursor = next;
                      LoopBodyInstructionExtent extent = loopBodyInstructionExtent(
                        assertionOpcode,
                        assertionOperand
                      );
                      if (extent.valid) {
                        productInstructions = extent.instructionCount;
                      } else {
                        statementValid = false;
                      }
                    }
                  }
                }
              } else {
                if (hash == TOKEN_RETURN) {
                  LoopBodyValue returned = resolveLoopBodyValue(
                    source,
                    tokenStarts[token + 1],
                    tokenLengths[token + 1],
                    owner,
                    statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement],
                    valueCount,
                    valueRows
                  );
                  if (returned.valid == false) {
                    statementValid = false;
                  }

                  long returnedLocal = physicalValueLocal(
                    owner,
                    returned.local,
                    statementCount,
                    statementRows,
                    statementLocalRows,
                    valueCount,
                    valueRows,
                    statementPhysicalStarts
                  );
                  if (returnedLocal < 0) {
                    statementValid = false;
                  }

                  long returnLocal = physicalStatementBase;
                  if (returnLocal < 0) {
                    statementValid = false;
                  }

                  if (255 < returnLocal) {
                    statementValid = false;
                  }

                  if (statementValid) {
                    cursor = writeInstructionHeader(
                      stagedCode,
                      cursor,
                      OPCODE_LOCAL_MOVE,
                      INSTRUCTION_FORM_BINARY
                    );
                    cursor = writeUnsignedLittleEndian(stagedCode, cursor, returnLocal, U64);
                    cursor = writeUnsignedLittleEndian(stagedCode, cursor, returnedLocal, U64);
                    cursor = writeInstructionHeader(
                      stagedCode,
                      cursor,
                      OPCODE_RETURN_VALUE,
                      INSTRUCTION_FORM_UNARY
                    );
                    cursor = writeUnsignedLittleEndian(stagedCode, cursor, returnLocal, U64);
                    set(stagedTypes, typeCount, owner);
                    set(stagedTypes, 4096 + typeCount, returnLocal);
                    set(stagedTypes, 8192 + typeCount, TYPE_SIGNED);
                    typeCount += 1;
                    productInstructions = 2;
                  }
                } else {
                  statementValid = false;
                }
              }
            }

            if (statementValid) {
              set(stagedRows, productCount, statement);
              set(stagedRows, 4096 + productCount, owner);
              set(stagedRows, 8192 + productCount, productInstructions);
              set(stagedRows, 12288 + productCount, productStart);
              set(stagedRows, 16384 + productCount, cursor - productStart);
              set(stagedRows, 20480 + productCount, productTypeStart);
              set(stagedRows, 24576 + productCount, typeCount - productTypeStart);
              set(stagedPhysicalWidths, statement, typeCount - productTypeStart);
              instructionCount += productInstructions;
              productCount += 1;
            } else {
              valid = false;
            }
          }
        }
      }

      processed += 1;
    }

    if (MAX_CODE_BYTES < cursor) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < DIRECT_ROWS) limit DIRECT_ROWS {
        set(directRows, row, stagedRows[row]);
        row += 1;
      }

      row = 0;
      while (row < TYPE_ROWS) limit TYPE_ROWS {
        set(typeRows, row, stagedTypes[row]);
        row += 1;
      }

      row = 0;
      while (row < MAX_STATEMENTS) limit MAX_STATEMENTS {
        set(statementPhysicalWidths, row, stagedPhysicalWidths[row]);
        row += 1;
      }

      long codeByte = 0;
      while (codeByte < cursor) limit MAX_CODE_BYTES {
        setByte(output, codeByte, stagedCode[codeByte]);
        codeByte += 1;
      }
    }

    drop(stagedCode);
    drop(stagedPhysicalWidths);
    drop(stagedTypes);
    drop(assertionBody);
    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new DirectStatementPlan(0, 0, 0, 0, false);
    }

    return new DirectStatementPlan(productCount, instructionCount, cursor, typeCount, true);
  }
}
