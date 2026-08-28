//! Resolves one direct loop-body statement from retained source and value products.

module wheeler.compiler.closure.direct_loop_body_products;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.loop_buffer_operands;
import wheeler.compiler.closure.resolved_loop_buffer_products;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class DirectLoopBodyProducts {
  private const long LITERAL_INDEX_OFFSET_SCALE = 131072;
  private const long MAX_LITERAL_INDEX_OFFSET = 65535;
  private const long OPERAND_LITERAL = 0;
  private const long OPERAND_LOCAL = 1;

  /// Retains one direct statement's physical local, opcode, and operand product.
  public record DirectLoopBodyProduct(
    long localBase,
    long opcode,
    long operandKind,
    long operand,
    boolean valid
  ) {}

  private record Utf8LoopProjection(
    long opcode,
    long operand,
    boolean recognized,
    boolean valid
  ) {}

  private Utf8LoopProjection resolveUtf8LoopProjection(
    borrow utf8 source,
    long token,
    long owner,
    long ordinal,
    long valueCount,
    borrow mut words valueRows,
    long semanticCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long initializer = tokenHash(source, tokenStarts, tokenLengths, token);
    long opcode = BODY_UTF8_SCALAR;
    boolean recognized = initializer == TOKEN_UTF8_SCALAR;
    if (initializer == TOKEN_UTF8_WIDTH) {
      opcode = BODY_UTF8_WIDTH;
      recognized = true;
    }

    if (recognized == false) {
      return new Utf8LoopProjection(0, 0, false, false);
    }

    if (semanticCount < token + 7) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (tokenKinds[token + 2] != 1) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 3, PUNCTUATION_COMMA) == false
    ) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (tokenKinds[token + 4] != 1) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 5, PUNCTUATION_CLOSE_PAREN) == false
    ) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, token + 6, PUNCTUATION_SEMICOLON) == false
    ) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    LoopBodyValue text = resolveLoopBodyValue(
      source,
      tokenStarts[token + 2],
      tokenLengths[token + 2],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    LoopBodyValue index = resolveLoopBodyValue(
      source,
      tokenStarts[token + 4],
      tokenLengths[token + 4],
      owner,
      ordinal,
      valueCount,
      valueRows
    );
    if (text.valid == false) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (index.valid == false) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    long textType = directBufferLocalType(
      source,
      owner,
      text.local,
      valueCount,
      valueRows,
      semanticCount,
      tokenStarts,
      tokenLengths
    );
    if (textType != TYPE_UTF8_BORROW) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (
      signedLoopBodyLocal(
        source,
        owner,
        index.local,
        valueCount,
        valueRows,
        semanticCount,
        tokenStarts,
        tokenLengths
      ) == false
    ) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (255 < text.local) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    if (255 < index.local) {
      return new Utf8LoopProjection(0, 0, true, false);
    }

    return new Utf8LoopProjection(opcode, text.local * 256 + index.local, true, true);
  }

  /// Resolves one declaration, assertion, buffer operation, assignment, or update.
  public DirectLoopBodyProduct resolveDirectLoopBodyProduct(
    borrow utf8 source,
    long owner,
    long ordinal,
    long statementStart,
    long statementLength,
    long minimumLocalBase,
    long valueCount,
    borrow mut words valueRows,
    long semanticCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long localBase = localBaseAtOrdinal(owner, ordinal, valueCount, valueRows);
    long start = statementStart;
    long length = statementLength;
    long token = tokenAtStart(start, semanticCount, tokenStarts);
    boolean statementValid = -1 < token;
    if (length < 2) {
      statementValid = false;
    }

    if (localBase < minimumLocalBase) {
      localBase = minimumLocalBase;
    }

    long opcode = -1;
    long operandKind = OPERAND_LITERAL;
    long operand = 0;
    if (statementValid) {
      long statementHash = tokenHash(source, tokenStarts, tokenLengths, token);
      if (statementHash == TOKEN_BOOLEAN) {
        if (tokenKinds[token + 1] != 1) {
          statementValid = false;
        }

        if (
          punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN) == false
        ) {
          statementValid = false;
        }

        if (statementValid) {
          LoopBooleanDeclaration booleanPlan = resolveLoopBooleanDeclaration(
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
          if (booleanPlan.valid) {
            localBase = booleanPlan.localBase;
            opcode = booleanPlan.opcode;
            operand = booleanPlan.operand;
          } else {
            statementValid = false;
          }
        }
      } else {
        if (statementHash == TOKEN_LONG) {
          if (tokenKinds[token + 1] != 1) {
            statementValid = false;
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN) == false
          ) {
            statementValid = false;
          }

          if (statementValid) {
            LoopBodyValue declaration = resolveLoopBodyValue(
              source,
              tokenStarts[token + 1],
              tokenLengths[token + 1],
              owner,
              ordinal + 1,
              valueCount,
              valueRows
            );
            if (declaration.valid) {
              localBase = declaration.local - 1;
            } else {
              statementValid = false;
            }

            long sourceToken = token + 3;
            Utf8LoopProjection utf8Projection = resolveUtf8LoopProjection(
              source,
              sourceToken,
              owner,
              ordinal,
              valueCount,
              valueRows,
              semanticCount,
              tokenKinds,
              tokenStarts,
              tokenLengths
            );
            if (utf8Projection.recognized) {
              if (utf8Projection.valid) {
                localBase = declaration.local - 3;
                opcode = utf8Projection.opcode;
                operand = utf8Projection.operand;
              } else {
                statementValid = false;
              }
            } else {
              if (tokenKinds[sourceToken] == 1) {
                LoopBodyValue sourceValue = resolveLoopBodyValue(
                  source,
                  tokenStarts[sourceToken],
                  tokenLengths[sourceToken],
                  owner,
                  ordinal,
                  valueCount,
                  valueRows
                );
                if (sourceValue.valid) {
                  if (
                    punctuationAt(
                      source,
                      tokenKinds,
                      tokenStarts,
                      sourceToken + 1,
                      PUNCTUATION_OPEN_SQUARE
                    )
                  ) {
                    long indexToken = sourceToken + 2;
                    long indexOffset = 0;
                    boolean offsetIndex = false;
                    if (
                      signedNumberWidth(source, tokenKinds, tokenStarts, indexToken) == 1
                    ) {
                      if (
                        signedNumberValid(source, tokenStarts, tokenLengths, indexToken)
                      ) {
                        if (
                          punctuationAt(
                            source,
                            tokenKinds,
                            tokenStarts,
                            indexToken + 1,
                            PUNCTUATION_PLUS
                          )
                        ) {
                          indexOffset = parsedSignedNumber(
                            source,
                            tokenStarts,
                            tokenLengths,
                            indexToken
                          );
                          if (indexOffset < 0) {
                            statementValid = false;
                          } else {
                            indexToken += 2;
                            offsetIndex = true;
                          }
                        }
                      }
                    }

                    LoopBodyValue indexValue = resolveLoopBodyValue(
                      source,
                      tokenStarts[indexToken],
                      tokenLengths[indexToken],
                      owner,
                      ordinal,
                      valueCount,
                      valueRows
                    );
                    if (indexValue.valid) {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          indexToken + 1,
                          PUNCTUATION_CLOSE_SQUARE
                        )
                      ) {
                        LoopBufferOperand read = resolveLoopBufferReadOperand(
                          source,
                          owner,
                          sourceValue.local,
                          indexValue.local,
                          valueCount,
                          valueRows,
                          semanticCount,
                          tokenStarts,
                          tokenLengths
                        );
                        if (read.valid) {
                          localBase = localBase - 1;
                          if (0 < read.operand / 65536) {
                            localBase -= 1;
                          }

                          if (offsetIndex) {
                            localBase -= 2;
                          }

                          long sourceType = loopBodyValueType(
                            source,
                            owner,
                            sourceValue.local,
                            valueCount,
                            valueRows,
                            semanticCount,
                            tokenStarts,
                            tokenLengths
                          );
                          opcode = BODY_WORDS_GET;
                          if (sourceType == TOKEN_BYTES) {
                            opcode = BODY_BYTES_GET;
                          }

                          if (sourceType == TOKEN_BYTEVIEW) {
                            opcode = BODY_BYTEVIEW_GET;
                          }

                          operand = read.operand;
                          if (offsetIndex) {
                            if (MAX_LITERAL_INDEX_OFFSET < indexOffset) {
                              statementValid = false;
                            }

                            if (opcode == BODY_WORDS_GET) {
                              opcode = BODY_WORDS_GET_OFFSET;
                              operand += indexOffset * LITERAL_INDEX_OFFSET_SCALE;
                            } else {
                              statementValid = false;
                            }
                          }
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
                      opcode = STATEMENT_LOCAL_LONG_COPY_BASE + sourceValue.local;
                      operandKind = OPERAND_LOCAL;
                      operand = sourceValue.local;
                    } else {
                      statementValid = false;
                    }
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
                    opcode = STATEMENT_LOCAL_LONG;
                    operand = parsedSignedNumber(source, tokenStarts, tokenLengths, sourceToken);
                  } else {
                    statementValid = false;
                  }
                }
              }
            }
          }
        } else {
          long bufferHash = tokenHash(source, tokenStarts, tokenLengths, token);
          boolean bufferStatement = bufferHash == TOKEN_SET;
          if (bufferHash == TOKEN_SET_BYTE) {
            bufferStatement = true;
          }

          if (bufferStatement) {
            ResolvedLoopBufferProduct buffer = resolveLoopBufferProduct(
              source,
              owner,
              ordinal,
              token,
              valueCount,
              valueRows,
              semanticCount,
              tokenKinds,
              tokenStarts,
              tokenLengths
            );
            if (buffer.valid) {
              opcode = buffer.opcode;
              operand = buffer.operand;
            } else {
              statementValid = false;
            }
          } else {
            if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_ASSERT) {
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
              if (assertion.valid) {
                opcode = assertion.opcode;
                operandKind = assertion.operandKind;
                operand = assertion.operand;
              } else {
                statementValid = false;
              }
            } else {
              LoopBodyValue target = resolveLoopBodyValue(
                source,
                tokenStarts[token],
                tokenLengths[token],
                owner,
                ordinal,
                valueCount,
                valueRows
              );
              if (target.valid == false) {
                statementValid = false;
              }

              if (
                punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_ASSIGN)
              ) {
                boolean targetBoolean = false;
                boolean targetSigned = false;
                if (target.valid) {
                  targetBoolean = booleanLoopBodyLocal(
                    source,
                    owner,
                    target.local,
                    valueCount,
                    valueRows,
                    semanticCount,
                    tokenStarts,
                    tokenLengths
                  );
                  targetSigned = signedLoopBodyLocal(
                    source,
                    owner,
                    target.local,
                    valueCount,
                    valueRows,
                    semanticCount,
                    tokenStarts,
                    tokenLengths
                  );
                  if (targetBoolean == false) {
                    if (targetSigned == false) {
                      statementValid = false;
                    }
                  }
                }

                long assignmentSourceToken = token + 2;
                if (tokenKinds[assignmentSourceToken] == 1) {
                  long assignmentHash = tokenHash(
                    source,
                    tokenStarts,
                    tokenLengths,
                    assignmentSourceToken
                  );
                  if (targetBoolean) {
                    if (assignmentHash == TOKEN_TRUE) {
                      opcode = BODY_ASSIGN_BOOLEAN_LITERAL_BASE + target.local;
                      operand = 1;
                    } else {
                      if (assignmentHash == TOKEN_FALSE) {
                        opcode = BODY_ASSIGN_BOOLEAN_LITERAL_BASE + target.local;
                        operand = 0;
                      } else {
                        LoopBodyValue booleanSource = resolveLoopBodyValue(
                          source,
                          tokenStarts[assignmentSourceToken],
                          tokenLengths[assignmentSourceToken],
                          owner,
                          ordinal,
                          valueCount,
                          valueRows
                        );
                        if (booleanSource.valid) {
                          if (
                            booleanLoopBodyLocal(
                              source,
                              owner,
                              booleanSource.local,
                              valueCount,
                              valueRows,
                              semanticCount,
                              tokenStarts,
                              tokenLengths
                            )
                          ) {
                            opcode = BODY_ASSIGN_BOOLEAN_LOCAL_BASE + target.local;
                            operandKind = OPERAND_LOCAL;
                            operand = booleanSource.local;
                          } else {
                            statementValid = false;
                          }
                        } else {
                          statementValid = false;
                        }
                      }
                    }
                  } else {
                    LoopBodyValue assignmentSource = resolveLoopBodyValue(
                      source,
                      tokenStarts[assignmentSourceToken],
                      tokenLengths[assignmentSourceToken],
                      owner,
                      ordinal,
                      valueCount,
                      valueRows
                    );
                    if (assignmentSource.valid) {
                      if (
                        signedLoopBodyLocal(
                          source,
                          owner,
                          assignmentSource.local,
                          valueCount,
                          valueRows,
                          semanticCount,
                          tokenStarts,
                          tokenLengths
                        )
                      ) {
                        opcode = STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + target.local;
                        operandKind = OPERAND_LOCAL;
                        operand = assignmentSource.local;
                      } else {
                        statementValid = false;
                      }
                    } else {
                      statementValid = false;
                    }
                  }
                } else {
                  if (targetBoolean) {
                    statementValid = false;
                  } else {
                    if (
                      signedNumberWidth(source, tokenKinds, tokenStarts, assignmentSourceToken) != 1
                    ) {
                      statementValid = false;
                    } else {
                      if (
                        signedNumberValid(
                          source,
                          tokenStarts,
                          tokenLengths,
                          assignmentSourceToken
                        )
                      ) {
                        opcode = STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE + target.local;
                        operand = parsedSignedNumber(
                          source,
                          tokenStarts,
                          tokenLengths,
                          assignmentSourceToken
                        );
                      } else {
                        statementValid = false;
                      }
                    }
                  }
                }
              } else {
                long operation = 0;
                if (
                  punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_PLUS)
                ) {
                  operation = STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
                }

                if (
                  punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_MINUS)
                ) {
                  operation = STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
                }

                if (
                  punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_CARET)
                ) {
                  operation = STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
                }

                if (operation == 0) {
                  statementValid = false;
                }

                if (
                  punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN)
                    == false
                ) {
                  statementValid = false;
                }

                if (statementValid) {
                  long updateSourceToken = token + 3;
                  if (tokenKinds[updateSourceToken] == 1) {
                    LoopBodyValue updateSourceValue = resolveLoopBodyValue(
                      source,
                      tokenStarts[updateSourceToken],
                      tokenLengths[updateSourceToken],
                      owner,
                      ordinal,
                      valueCount,
                      valueRows
                    );
                    if (updateSourceValue.valid) {
                      opcode = operation + 256 + target.local;
                      operandKind = OPERAND_LOCAL;
                      operand = updateSourceValue.local;
                    } else {
                      statementValid = false;
                    }
                  } else {
                    if (
                      signedNumberWidth(source, tokenKinds, tokenStarts, updateSourceToken) != 1
                    ) {
                      statementValid = false;
                    } else {
                      if (
                        signedNumberValid(source, tokenStarts, tokenLengths, updateSourceToken)
                      ) {
                        opcode = operation + target.local;
                        operand = parsedSignedNumber(
                          source,
                          tokenStarts,
                          tokenLengths,
                          updateSourceToken
                        );
                      } else {
                        statementValid = false;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return new DirectLoopBodyProduct(localBase, opcode, operandKind, operand, statementValid);
  }
}
