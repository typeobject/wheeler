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

  /// Emits literal and prior-local declarations plus local returns in source order.
  public DirectStatementPlan materializeDirectStatementProducts(
    borrow utf8 source,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words callableReturnLocals,
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
    assert(bufferLength(callableReturnLocals) == 64);
    assert(bufferLength(directRows) == DIRECT_ROWS);
    assert(bufferLength(typeRows) == TYPE_ROWS);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ 851968, /* allocations= */ 7);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, DIRECT_ROWS);
    words assertionBody = allocate(staging, BODY_ROWS);
    words stagedTypes = allocate(staging, TYPE_ROWS);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
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

              long localBase = destination.local - 1;
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
                    sourceOperand = sourceValue.local;
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
                cursor = writeUnsignedLittleEndian(stagedCode, cursor, destination.local, U64);
                cursor = writeUnsignedLittleEndian(stagedCode, cursor, localBase, U64);
                set(stagedTypes, typeCount, owner);
                set(stagedTypes, 4096 + typeCount, localBase);
                set(stagedTypes, 8192 + typeCount, TYPE_SIGNED);
                typeCount += 1;
                set(stagedTypes, typeCount, owner);
                set(stagedTypes, 4096 + typeCount, destination.local);
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

                long assertionLocalBase = localBaseAtOrdinal(
                  owner,
                  ordinal,
                  valueCount,
                  valueRows
                );
                if (statementValid) {
                  set(assertionBody, BODY_LOCAL_BASE_ROW, assertionLocalBase);
                  set(assertionBody, BODY_OPCODE_ROW, assertion.opcode);
                  set(assertionBody, BODY_OPERAND_KIND_ROW, assertion.operandKind);
                  set(assertionBody, BODY_OPERAND_ROW, assertion.operand);
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
                        assertion.opcode,
                        assertion.operand
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

                  long returnLocal = callableReturnLocals[owner];
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
                    cursor = writeUnsignedLittleEndian(stagedCode, cursor, returned.local, U64);
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

      long codeByte = 0;
      while (codeByte < cursor) limit MAX_CODE_BYTES {
        setByte(output, codeByte, stagedCode[codeByte]);
        codeByte += 1;
      }
    }

    drop(stagedCode);
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
