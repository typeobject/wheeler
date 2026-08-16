//! Emits roots.

module wheeler.compiler.closure.direct_statement_products;

import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.result_slot_codegen;
import wheeler.compiler.source_scalars;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;
import wheeler.lexer.scanner;

classical class DirectStatementProducts {
  private const long DIRECT_ROWS = 28672;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_STATEMENTS = 4096;
  private const long TYPE_ROWS = 12288;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports extents.
  public record DirectStatementPlan(
    long productCount,
    long instructionCount,
    long length,
    long typeCount,
    long failureStatement,
    boolean valid
  ) {}

  /// Emits roots in source order.
  public DirectStatementPlan materializeDirectStatementProducts(
    borrow utf8 source,
    long moduleOwner,
    long reversibleCallableCount,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    long statementCount,
    borrow mut words statementRows,
    long callCount,
    borrow mut words callStatements,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    borrow mut words statementPhysicalWidths,
    borrow mut words directRows,
    borrow mut words functionResultTypes,
    borrow mut words typeRows,
    borrow mut bytes output
  ) {
    assert(-1 < moduleOwner);
    assert(-1 < reversibleCallableCount);
    assert(reversibleCallableCount < 65);
    assert(-1 < symbolCount);
    assert(symbolCount < 16385);
    assert(bufferLength(symbolOwners) == 16384);
    assert(bufferLength(symbolStarts) == 16384);
    assert(bufferLength(symbolLengths) == 16384);
    assert(bufferLength(symbolTypes) == 16384);
    assert(bufferLength(symbolValues) == 16384);
    assert(bufferLength(symbolResolved) == 16384);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < callCount);
    assert(callCount < 257);
    if (0 < callCount) {
      assert(bufferLength(callStatements) == 256);
    }

    assert(-1 < valueCount);
    assert(valueCount < LOOP_VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == LOOP_VALUE_ROWS);
    assert(bufferLength(statementLocalRows) == 8192);
    assert(bufferLength(statementPhysicalStarts) == MAX_STATEMENTS);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);
    assert(bufferLength(directRows) == DIRECT_ROWS);
    assert(bufferLength(functionResultTypes) == 64);
    assert(bufferLength(typeRows) == TYPE_ROWS);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ 885248, /* allocations= */ 9);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, DIRECT_ROWS);
    words assertionBody = allocate(staging, BODY_ROWS);
    words stagedTypes = allocate(staging, TYPE_ROWS);
    words stagedResultTypes = allocate(staging, /* length= */ 64);
    words stagedPhysicalWidths = allocate(staging, MAX_STATEMENTS);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    long stagedStatement = 0;
    while (stagedStatement < MAX_STATEMENTS) limit MAX_STATEMENTS {
      set(stagedPhysicalWidths, stagedStatement, statementPhysicalWidths[stagedStatement]);
      stagedStatement += 1;
    }

    long resultCallable = 0;
    while (resultCallable < 64) limit 64 {
      set(stagedResultTypes, resultCallable, functionResultTypes[resultCallable]);
      resultCallable += 1;
    }

    boolean valid = true;
    long failureStatement = -1;
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
            boolean selectedCall = -1 < callAtStatement(statement, callCount, callStatements);
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
              DirectScalarRelationProduct initializer = resolveDirectScalarRelation(
                source,
                sourceToken,
                semanticCount,
                tokenKinds,
                tokenStarts,
                tokenLengths,
                moduleOwner,
                owner,
                statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement],
                statementCount,
                statementRows,
                statementLocalRows,
                statementPhysicalStarts,
                valueCount,
                valueRows,
                symbolCount,
                symbolOwners,
                symbolStarts,
                symbolLengths,
                symbolTypes,
                symbolValues,
                symbolResolved
              );
              boolean binaryInitializer = initializer.valid;
              if (binaryInitializer) {
                binaryInitializer = initializer.kind != RESULT_RELATION_SOURCE;
              }

              boolean bufferLengthInitializer = false;
              if (tokenKinds[sourceToken] == 1) {
                if (
                  tokenHash(source, tokenStarts, tokenLengths, sourceToken) == TOKEN_BUFFER_LENGTH
                ) {
                  bufferLengthInitializer = punctuationAt(
                    source,
                    tokenKinds,
                    tokenStarts,
                    sourceToken + 1,
                    40
                  );
                }
              }

              if (bufferLengthInitializer) {
                if (tokenKinds[sourceToken + 2] != 1) {
                  statementValid = false;
                }

                if (
                  punctuationAt(source, tokenKinds, tokenStarts, sourceToken + 3, 41) == false
                ) {
                  statementValid = false;
                }

                if (
                  punctuationAt(
                    source,
                    tokenKinds,
                    tokenStarts,
                    sourceToken + 4,
                    PUNCTUATION_SEMICOLON
                  ) == false
                ) {
                  statementValid = false;
                }

                LoopBodyValue bufferSourceValue = resolveLoopBodyValue(
                  source,
                  tokenStarts[sourceToken + 2],
                  tokenLengths[sourceToken + 2],
                  owner,
                  statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement],
                  valueCount,
                  valueRows
                );
                if (bufferSourceValue.valid == false) {
                  statementValid = false;
                }

                long bufferSourceOperand = physicalValueLocal(
                  owner,
                  bufferSourceValue.local,
                  statementCount,
                  statementRows,
                  statementLocalRows,
                  valueCount,
                  valueRows,
                  statementPhysicalStarts
                );
                if (bufferSourceOperand < 0) {
                  statementValid = false;
                }

                long bufferSourceType = directBufferLocalType(
                  source,
                  owner,
                  bufferSourceValue.local,
                  valueCount,
                  valueRows,
                  semanticCount,
                  tokenStarts,
                  tokenLengths
                );
                if (bufferSourceType < 0) {
                  statementValid = false;
                }

                destinationLocal = localBase + 2;
                if (statementValid) {
                  cursor = writeInstructionHeader(
                    stagedCode,
                    cursor,
                    OPCODE_LOCAL_MOVE,
                    INSTRUCTION_FORM_BINARY
                  );
                  cursor = writeUnsignedLittleEndian(stagedCode, cursor, localBase, U64);
                  cursor = writeUnsignedLittleEndian(
                    stagedCode,
                    cursor,
                    bufferSourceOperand,
                    U64
                  );
                  cursor = writeInstructionHeader(
                    stagedCode,
                    cursor,
                    OPCODE_BUFFER_LENGTH,
                    INSTRUCTION_FORM_BINARY
                  );
                  cursor = writeUnsignedLittleEndian(stagedCode, cursor, localBase + 1, U64);
                  cursor = writeUnsignedLittleEndian(stagedCode, cursor, localBase, U64);
                  cursor = writeInstructionHeader(
                    stagedCode,
                    cursor,
                    OPCODE_LOCAL_MOVE,
                    INSTRUCTION_FORM_BINARY
                  );
                  cursor = writeUnsignedLittleEndian(stagedCode, cursor, destinationLocal, U64);
                  cursor = writeUnsignedLittleEndian(stagedCode, cursor, localBase + 1, U64);
                  set(stagedTypes, typeCount, owner);
                  set(stagedTypes, 4096 + typeCount, localBase);
                  set(stagedTypes, 8192 + typeCount, bufferSourceType);
                  typeCount += 1;
                  long signedOffset = 1;
                  while (signedOffset < 3) limit 2 {
                    set(stagedTypes, typeCount, owner);
                    set(stagedTypes, 4096 + typeCount, localBase + signedOffset);
                    set(stagedTypes, 8192 + typeCount, TYPE_SIGNED);
                    typeCount += 1;
                    signedOffset += 1;
                  }

                  productInstructions = 3;
                }
              } else {
                if (binaryInitializer) {
                  boolean initializerTypesValid = directReturnTypesValid(
                    /* reversibleCallableCount= */ 0,
                    initializer.kind,
                    initializer.operation,
                    initializer.leftType,
                    initializer.rightType
                  );
                  if (initializer.leftType != TOKEN_LONG) {
                    initializerTypesValid = false;
                  }

                  if (initializer.rightType != TOKEN_LONG) {
                    initializerTypesValid = false;
                  }

                  if (initializerTypesValid == false) {
                    statementValid = false;
                  }

                  if (statementValid) {
                    DirectScalarExtent emitted = writeDirectScalarDeclaration(
                      stagedCode,
                      cursor,
                      initializer.kind,
                      localBase,
                      initializer.left,
                      initializer.operation,
                      initializer.right,
                      initializer.immediate
                    );
                    if (emitted.valid) {
                      cursor = emitted.next;
                      destinationLocal = localBase + 3;
                      long scalarOffset = 0;
                      while (scalarOffset < emitted.localCount) limit 4 {
                        set(stagedTypes, typeCount, owner);
                        set(stagedTypes, 4096 + typeCount, localBase + scalarOffset);
                        set(stagedTypes, 8192 + typeCount, TYPE_SIGNED);
                        typeCount += 1;
                        scalarOffset += 1;
                      }

                      productInstructions = emitted.instructionCount;
                    } else {
                      statementValid = false;
                    }
                  }
                }

                if (binaryInitializer == false) {
                  long sourceOpcode = OPCODE_LOCAL_CONST;
                  long sourceOperand = 0;
                  if (tokenKinds[sourceToken] == 1) {
                    if (initializer.valid) {
                      if (initializer.kind == RESULT_RELATION_SOURCE) {
                        if (initializer.leftType == TOKEN_LONG) {
                          sourceOpcode = OPCODE_LOCAL_MOVE;
                          sourceOperand = initializer.left;
                        } else {
                          statementValid = false;
                        }
                      } else {
                        statementValid = false;
                      }
                    } else {
                      statementValid = false;
                    }
                  } else {
                    long signedWidth = signedNumberWidth(
                      source,
                      tokenKinds,
                      tokenStarts,
                      sourceToken
                    );
                    if (signedWidth < 1) {
                      statementValid = false;
                    } else {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          sourceToken + signedWidth,
                          PUNCTUATION_SEMICOLON
                        ) == false
                      ) {
                        statementValid = false;
                      }

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
                    cursor = writeUnsignedLittleEndian(
                      stagedCode,
                      cursor,
                      destinationLocal,
                      U64
                    );
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
                }
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
                long assertionOpcode = physicalDirectAssertionOpcode(
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
                  DirectScalarRelationProduct relation = resolveDirectScalarRelation(
                    source,
                    token + 1,
                    semanticCount,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths,
                    moduleOwner,
                    owner,
                    statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement],
                    statementCount,
                    statementRows,
                    statementLocalRows,
                    statementPhysicalStarts,
                    valueCount,
                    valueRows,
                    symbolCount,
                    symbolOwners,
                    symbolStarts,
                    symbolLengths,
                    symbolTypes,
                    symbolValues,
                    symbolResolved
                  );
                  if (relation.valid == false) {
                    statementValid = false;
                  }

                  long returnedType = directReturnType(relation.leftType);
                  if (returnedType < 0) {
                    statementValid = false;
                  }

                  if (stagedResultTypes[owner] == 0) {
                    set(stagedResultTypes, owner, returnedType);
                  } else {
                    if (stagedResultTypes[owner] != returnedType) {
                      statementValid = false;
                    }
                  }

                  if (
                    directReturnTypesValid(
                      reversibleCallableCount,
                      relation.kind,
                      relation.operation,
                      relation.leftType,
                      relation.rightType
                    ) == false
                  ) {
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
                    long returnWidth = 1;
                    if (0 < reversibleCallableCount) {
                      if (relation.kind == RESULT_RELATION_SOURCE) {
                        cursor = writeResultSlotSourceBody(
                          stagedCode,
                          cursor,
                          returnLocal,
                          relation.left
                        );
                      }

                      if (relation.kind == RESULT_RELATION_BINARY) {
                        cursor = writeResultSlotBinaryBody(
                          stagedCode,
                          cursor,
                          returnLocal,
                          relation.left,
                          relation.operation,
                          relation.immediate
                        );
                      }

                      if (relation.kind == RESULT_RELATION_BINARY_SOURCES) {
                        cursor = writeResultSlotBinarySourcesBody(
                          stagedCode,
                          cursor,
                          returnLocal,
                          relation.left,
                          relation.operation,
                          relation.right
                        );
                      }

                      productInstructions = 2;
                    } else {
                      DirectReturnExtent written = writeDirectReturn(
                        stagedCode,
                        cursor,
                        relation.kind,
                        returnLocal,
                        relation.left,
                        relation.operation,
                        relation.right,
                        relation.immediate
                      );
                      if (written.valid) {
                        cursor = written.next;
                        productInstructions = written.instructionCount;
                        returnWidth = written.localCount;
                      } else {
                        statementValid = false;
                      }
                    }

                    if (statementValid) {
                      long returnOffset = 0;
                      while (returnOffset < returnWidth) limit 3 {
                        set(stagedTypes, typeCount, owner);
                        set(stagedTypes, 4096 + typeCount, returnLocal + returnOffset);
                        set(stagedTypes, 8192 + typeCount, returnedType);
                        typeCount += 1;
                        returnOffset += 1;
                      }
                    }
                  }
                } else {
                  statementValid = false;
                }
              }
            }

            if (selectedCall) {
              statementValid = true;
              cursor = productStart;
              typeCount = productTypeStart;
            }

            if (statementValid) {
              if (selectedCall == false) {
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
              }
            } else {
              if (failureStatement < 0) {
                failureStatement = statement;
              }

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
      while (row < 64) limit 64 {
        set(functionResultTypes, row, stagedResultTypes[row]);
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
    drop(stagedResultTypes);
    drop(stagedTypes);
    drop(assertionBody);
    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new DirectStatementPlan(0, 0, 0, 0, failureStatement, false);
    }

    return new DirectStatementPlan(productCount, instructionCount, cursor, typeCount, -1, true);
  }
}
