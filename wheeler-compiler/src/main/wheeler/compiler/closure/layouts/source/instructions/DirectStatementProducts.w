//! Stages complete root-statement code, types, and physical coordinates before publication.

module wheeler.compiler.closure.direct_statement_products;

import wheeler.compiler.closure.direct_assertion_products;
import wheeler.compiler.closure.direct_boolean_declaration_products;
import wheeler.compiler.closure.direct_buffer_mutation_products;
import wheeler.compiler.closure.direct_call_conditional_returns;
import wheeler.compiler.closure.direct_conditional_return_products;
import wheeler.compiler.closure.direct_global_store_products;
import wheeler.compiler.closure.direct_long_declaration_products;
import wheeler.compiler.closure.direct_return_instructions;
import wheeler.compiler.closure.direct_scalar_encoding;
import wheeler.compiler.closure.direct_scalar_relations;
import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.direct_statement_publication;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_call_layout_products;
import wheeler.compiler.closure.source_global_references;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;
import wheeler.lexer.scanner;

classical class DirectStatementProducts {
  private const long U64 = ENCODING_WIDTH_U64;

  /// Emits roots in source order.
  public DirectStatementPlan materializeDirectStatementProducts(
    borrow utf8 source,
    borrow byteview symbolNames,
    borrow byteview globalNames,
    long globalCount,
    long globalProductStart,
    borrow mut words globals,
    long moduleOwner,
    long reversibleCallableCount,
    long functionCount,
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
    borrow mut words callRows,
    borrow mut words callStatements,
    borrow mut words callArgumentCounts,
    borrow mut words callLocalWidths,
    borrow mut words callConditionalValues,
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
    assert(-1 < functionCount);
    assert(functionCount < 65);
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
      assert(bufferLength(callRows) == 1024);
      assert(bufferLength(callStatements) == 256);
      assert(bufferLength(callArgumentCounts) == 256);
      assert(bufferLength(callLocalWidths) == 256);
      assert(bufferLength(callConditionalValues) == 256);
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

    requireSourceGlobalScope(
      globalNames,
      globalCount,
      globalProductStart,
      globals,
      symbolNames,
      moduleOwner,
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths
    );
    region staging = new region(DIRECT_STAGING_BYTES, DIRECT_STAGING_BUFFERS);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, DIRECT_ROWS);
    words stagedTypes = allocate(staging, TYPE_ROWS);
    words stagedResultTypes = allocate(staging, DIRECT_FUNCTIONS);
    words stagedCallKinds = allocate(staging, DIRECT_CALLS);
    words stagedCallConditionalValues = allocate(staging, DIRECT_CALLS);
    words stagedPhysicalWidths = allocate(staging, MAX_STATEMENTS);
    words functionInstructionCounts = allocate(staging, DIRECT_FUNCTIONS);
    words functionPrefixesComplete = allocate(staging, DIRECT_FUNCTIONS);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    long stagedCall = 0;
    while (stagedCall < callCount) limit 256 {
      set(stagedCallKinds, stagedCall, callRows[256 + stagedCall]);
      set(stagedCallConditionalValues, stagedCall, callConditionalValues[stagedCall]);
      stagedCall += 1;
    }

    long stagedStatement = 0;
    while (stagedStatement < statementCount) limit MAX_STATEMENTS {
      set(stagedPhysicalWidths, stagedStatement, statementPhysicalWidths[stagedStatement]);
      stagedStatement += 1;
    }

    long resultCallable = 0;
    while (resultCallable < functionCount) limit 64 {
      set(stagedResultTypes, resultCallable, functionResultTypes[resultCallable]);
      set(functionPrefixesComplete, resultCallable, 1);
      resultCallable += 1;
    }

    boolean valid = true;
    long failureStatement = -1;
    long failureCode = 0;
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
    long rootOwner = -1;
    long rootBlock = -1;
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
        if (owner != rootOwner) {
          rootOwner = owner;
          rootBlock = loopBodyRootBlockForOwner(owner, statementCount, statementRows);
        }

        if (statementRows[4096 + statement] == rootBlock) {
          long rootToken = tokenAtStart(
            statementRows[LOOP_STATEMENT_START_ROW + statement],
            semanticCount,
            tokenStarts
          );
          long rootWordCode = 0;
          if (-1 < rootToken) {
            rootWordCode = sourceTokenCode(source, tokenStarts, tokenLengths, rootToken);
          }

          long childCount = statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement];
          boolean productStatement = childCount == 0;
          if (childCount == 1) {
            if (rootWordCode == TOKEN_IF) {
              productStatement = true;
            } else {
              set(functionPrefixesComplete, owner, 0);
            }
          }

          if (productStatement) {
            long physicalStatementBase = statementPhysicalStarts[statement];
            long token = rootToken;
            boolean statementValid = -1 < token;
            long productStart = cursor;
            long productInstructions = 0;
            long productTypeStart = typeCount;
            long wordCode = rootWordCode;
            boolean preserveStatementWidth = false;
            long statementCall = callAtStatement(statement, callCount, callStatements);
            boolean selectedCall = -1 < statementCall;
            if (wordCode == TOKEN_IF) {
              if (0 < reversibleCallableCount) {
                statementValid = false;
              }

              if (selectedCall) {
                if (statementValid) {
                  DirectCallConditionalReturn callConditional = directCallConditionalReturn(
                    source,
                    symbolNames,
                    token,
                    semanticCount,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths,
                    moduleOwner,
                    symbolCount,
                    symbolOwners,
                    symbolStarts,
                    symbolLengths,
                    symbolTypes,
                    symbolValues,
                    symbolResolved,
                    callRows[512 + statementCall],
                    callLocalWidths[statementCall],
                    owner,
                    statement,
                    statementCount,
                    statementRows,
                    statementLocalRows,
                    statementPhysicalStarts
                  );
                  if (callConditional.valid) {
                    set(stagedCallKinds, statementCall, callConditional.callKind);
                    set(stagedCallConditionalValues, statementCall, callConditional.childValue);
                    long conditionalResultType = TYPE_BOOLEAN;
                    if (sourceCallReturnsSignedChild(callConditional.callKind)) {
                      conditionalResultType = TYPE_SIGNED;
                    }

                    if (stagedResultTypes[owner] == 0) {
                      set(stagedResultTypes, owner, conditionalResultType);
                    } else {
                      if (stagedResultTypes[owner] != conditionalResultType) {
                        statementValid = false;
                      }
                    }
                  } else {
                    failureCode = callConditional.failureCode;
                    statementValid = false;
                  }
                }
              } else {
                if (functionPrefixesComplete[owner] != 1) {
                  statementValid = false;
                }

                if (statementValid) {
                  DirectConditionalReturnProduct conditional = writeDirectConditionalReturn(
                    source,
                    symbolNames,
                    globalNames,
                    globalCount,
                    globalProductStart,
                    globals,
                    token,
                    semanticCount,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths,
                    moduleOwner,
                    owner,
                    statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement],
                    statement,
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
                    symbolResolved,
                    stagedTypes,
                    typeCount,
                    stagedCode,
                    cursor,
                    functionInstructionCounts[owner]
                  );
                  if (conditional.valid) {
                    cursor = conditional.next;
                    typeCount = conditional.typeCount;
                    productInstructions = conditional.instructionCount;
                    preserveStatementWidth = true;
                    if (stagedResultTypes[owner] == 0) {
                      set(stagedResultTypes, owner, conditional.resultType);
                    } else {
                      if (stagedResultTypes[owner] != conditional.resultType) {
                        statementValid = false;
                      }
                    }
                  } else {
                    failureCode = conditional.failureCode;
                    statementValid = false;
                  }
                }
              }
            } else {
              if (wordCode == TOKEN_BOOLEAN) {
                DirectBooleanDeclarationProduct booleanDeclaration = writeDirectBooleanDeclaration(
                  source,
                  symbolNames,
                  globalNames,
                  globalCount,
                  globalProductStart,
                  globals,
                  token,
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
                  symbolResolved,
                  stagedTypes,
                  typeCount,
                  stagedCode,
                  cursor,
                  physicalStatementBase
                );
                if (booleanDeclaration.valid) {
                  cursor = booleanDeclaration.next;
                  typeCount = booleanDeclaration.typeCount;
                  productInstructions = booleanDeclaration.instructionCount;
                } else {
                  statementValid = false;
                }
              } else {
                if (wordCode == TOKEN_LONG) {
                  DirectLongDeclarationProduct declaration = writeDirectLongDeclaration(
                    source,
                    symbolNames,
                    globalNames,
                    globalCount,
                    globalProductStart,
                    globals,
                    token,
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
                    symbolResolved,
                    stagedTypes,
                    typeCount,
                    stagedCode,
                    cursor,
                    physicalStatementBase
                  );
                  if (declaration.valid) {
                    cursor = declaration.next;
                    typeCount = declaration.typeCount;
                    productInstructions = declaration.instructionCount;
                  } else {
                    statementValid = false;
                  }
                } else {
                  boolean wordMutation = wordCode == TOKEN_SET;
                  boolean bufferMutation = wordMutation;
                  if (wordCode == TOKEN_SET_BYTE) {
                    bufferMutation = true;
                  }

                  if (bufferMutation) {
                    DirectBufferMutationProduct mutation = writeDirectBufferMutation(
                      source,
                      token,
                      semanticCount,
                      tokenKinds,
                      tokenStarts,
                      tokenLengths,
                      wordMutation,
                      owner,
                      statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement],
                      statementCount,
                      statementRows,
                      statementLocalRows,
                      statementPhysicalStarts,
                      valueCount,
                      valueRows,
                      stagedTypes,
                      typeCount,
                      stagedCode,
                      cursor,
                      physicalStatementBase
                    );
                    if (mutation.valid) {
                      cursor = mutation.next;
                      typeCount = mutation.typeCount;
                      productInstructions = 4;
                    } else {
                      statementValid = false;
                    }
                  } else {
                    if (wordCode == TOKEN_ASSERT) {
                      DirectAssertionProduct assertion = writeDirectAssertion(
                        source,
                        symbolNames,
                        globalNames,
                        globalCount,
                        globalProductStart,
                        globals,
                        token,
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
                        symbolResolved,
                        stagedTypes,
                        typeCount,
                        stagedCode,
                        cursor,
                        physicalStatementBase
                      );
                      if (assertion.valid) {
                        cursor = assertion.next;
                        typeCount = assertion.typeCount;
                        productInstructions = assertion.instructionCount;
                      } else {
                        statementValid = false;
                      }
                    } else {
                      if (wordCode == TOKEN_RETURN) {
                        DirectScalarRelationProduct relation = resolveDirectScalarValue(
                          source,
                          symbolNames,
                          globalNames,
                          globalCount,
                          globalProductStart,
                          globals,
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
                          symbolResolved,
                          PUNCTUATION_SEMICOLON
                        );
                        if (relation.valid == false) {
                          statementValid = false;
                        }

                        long returnedType = directRelationResultType(
                          relation.operation,
                          relation.leftType
                        );
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

                        long returnLocal = physicalStatementBase;
                        if (returnLocal < 0) {
                          statementValid = false;
                        }

                        if (255 < returnLocal) {
                          statementValid = false;
                        }

                        if (statementValid) {
                          DirectScalarExtent written = writeDirectReturnInstructions(
                            relation,
                            reversibleCallableCount,
                            stagedCode,
                            cursor,
                            returnLocal
                          );
                          long returnWidth = written.localCount;
                          if (written.valid) {
                            cursor = written.next;
                            productInstructions = written.instructionCount;
                          } else {
                            statementValid = false;
                          }

                          if (statementValid) {
                            long returnOffset = 0;
                            while (returnOffset < returnWidth) limit 3 {
                              long returnLocalType = returnedType;
                              if (relation.kind != RESULT_RELATION_SOURCE) {
                                if (returnOffset == 0) {
                                  returnLocalType = directReturnType(relation.leftType);
                                }

                                if (returnOffset == 1) {
                                  returnLocalType = directReturnType(relation.rightType);
                                }
                              }

                              set(stagedTypes, typeCount, owner);
                              set(stagedTypes, 4096 + typeCount, returnLocal + returnOffset);
                              set(stagedTypes, 8192 + typeCount, returnLocalType);
                              typeCount += 1;
                              returnOffset += 1;
                            }
                          }
                        }
                      } else {
                        statementValid = false;
                        if (reversibleCallableCount == 0) {
                          DirectScalarExtent stored = writeDirectGlobalStore(
                            source,
                            symbolNames,
                            globalNames,
                            globalCount,
                            globalProductStart,
                            globals,
                            token,
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
                            symbolResolved,
                            stagedCode,
                            cursor,
                            physicalStatementBase
                          );
                          if (stored.valid) {
                            cursor = stored.next;
                            productInstructions = stored.instructionCount;
                            long storeLocal = 0;
                            while (storeLocal < stored.localCount) limit 3 {
                              set(stagedTypes, typeCount, owner);
                              set(
                                stagedTypes,
                                MAX_STATEMENTS + typeCount,
                                physicalStatementBase + storeLocal
                              );
                              set(stagedTypes, MAX_STATEMENTS * 2 + typeCount, TYPE_SIGNED);
                              typeCount += 1;
                              storeLocal += 1;
                            }

                            statementValid = true;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            if (selectedCall) {
              if (wordCode != TOKEN_IF) {
                statementValid = true;
              }

              cursor = productStart;
              typeCount = productTypeStart;
              set(
                functionInstructionCounts,
                owner,
                functionInstructionCounts[owner] + sourceCallInstructionCount(
                  stagedCallKinds[statementCall],
                  callArgumentCounts[statementCall]
                )
              );
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
                if (preserveStatementWidth == false) {
                  set(stagedPhysicalWidths, statement, typeCount - productTypeStart);
                }

                set(
                  functionInstructionCounts,
                  owner,
                  functionInstructionCounts[owner] + productInstructions
                );
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

    DirectStatementPlan result = publishDirectStatements(
      productCount,
      instructionCount,
      cursor,
      typeCount,
      callCount,
      functionCount,
      statementCount,
      failureStatement,
      failureCode,
      valid,
      stagedRows,
      stagedCallKinds,
      stagedCallConditionalValues,
      stagedResultTypes,
      stagedTypes,
      stagedPhysicalWidths,
      stagedCode,
      directRows,
      callRows,
      callConditionalValues,
      functionResultTypes,
      typeRows,
      statementPhysicalWidths,
      output
    );

    drop(stagedCode);
    drop(functionPrefixesComplete);
    drop(functionInstructionCounts);
    drop(stagedPhysicalWidths);
    drop(stagedCallConditionalValues);
    drop(stagedCallKinds);
    drop(stagedResultTypes);
    drop(stagedTypes);
    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    return result;
  }
}
