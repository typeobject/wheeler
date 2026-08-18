//! Resolves direct loop-body declarations and updates against callable values.

module wheeler.compiler.closure.resolved_loop_body_products;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.direct_loop_body_products;
import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.loop_buffer_operands;
import wheeler.compiler.closure.loop_nested_conditions;
import wheeler.compiler.closure.resolved_loop_buffer_products;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ResolvedLoopBodyProducts {
  private const long LITERAL_INDEX_OFFSET_SCALE = 131072;
  private const long MAX_LITERAL_INDEX_OFFSET = 65535;
  private const long MAX_STATEMENTS = 4096;
  private const long OPERAND_LITERAL = 0;
  private const long OPERAND_LOCAL = 1;
  private const long STATEMENT_FIRST_CHILD_ROW = 20480;

  /// Reports one complete direct body-statement resolution pass.
  public record ResolvedLoopBodyPlan(
    long bodyCount,
    long nestedCount,
    long failureStatement,
    boolean valid
  ) {}

  private long callAtStatement(long statement, long callCount, borrow mut words callRows) {
    long selected = -1;
    long matches = 0;
    long call = 0;
    while (call < callCount) limit 256 {
      if (callRows[call] == statement) {
        selected = call;
        matches += 1;
      }

      call += 1;
    }

    if (1 < matches) {
      return -2;
    }

    return selected;
  }

  private boolean directConditionalChild(
    borrow utf8 source,
    long statement,
    long statementCount,
    borrow mut words statementRows,
    long rootBlock,
    long tokenCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement] != 0) {
      return false;
    }

    long childToken = tokenAtStart(
      statementRows[LOOP_STATEMENT_START_ROW + statement],
      tokenCount,
      tokenStarts
    );
    if (childToken < 0) {
      return false;
    }

    if (tokenCount < childToken + 3) {
      return false;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, childToken) != TOKEN_RETURN) {
      return false;
    }

    long literal = tokenHash(source, tokenStarts, tokenLengths, childToken + 1);
    boolean supportedReturn = literal == TOKEN_TRUE;
    if (literal == TOKEN_FALSE) {
      supportedReturn = true;
    }

    if (supportedReturn == false) {
      long signedWidth = signedNumberWidth(source, tokenKinds, tokenStarts, childToken + 1);
      if (0 < signedWidth) {
        if (childToken + signedWidth + 1 < tokenCount) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              childToken + signedWidth + 1,
              PUNCTUATION_SEMICOLON
            )
          ) {
            supportedReturn = signedNumberValid(
              source,
              tokenStarts,
              tokenLengths,
              childToken + 1
            );
          }
        }
      }
    }

    if (supportedReturn == false) {
      SourceReversibleResultRelation relation = sourceScalarRelation(
        source,
        childToken + 1,
        tokenCount,
        tokenKinds,
        tokenStarts,
        tokenLengths
      );
      supportedReturn = relation.valid;
    }

    if (supportedReturn == false) {
      return false;
    }

    long expectedSemicolonStart = statementRows[LOOP_STATEMENT_START_ROW + statement]
      + statementRows[LOOP_STATEMENT_LENGTH_ROW + statement] - 1;
    long semicolonToken = tokenAtStart(expectedSemicolonStart, tokenCount, tokenStarts);
    if (semicolonToken < 0) {
      return false;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, semicolonToken, PUNCTUATION_SEMICOLON) == false
    ) {
      return false;
    }

    long matches = 0;
    long parent = 0;
    while (parent < statementCount) limit MAX_STATEMENTS {
      if (statementRows[parent] == statementRows[statement]) {
        if (statementRows[4096 + parent] == rootBlock) {
          if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + parent] == 1) {
            if (
              statementRows[STATEMENT_FIRST_CHILD_ROW + parent] == statementRows[4096 + statement]
            ) {
              long parentToken = tokenAtStart(
                statementRows[LOOP_STATEMENT_START_ROW + parent],
                tokenCount,
                tokenStarts
              );
              if (-1 < parentToken) {
                if (
                  tokenHash(source, tokenStarts, tokenLengths, parentToken) == TOKEN_IF
                ) {
                  matches += 1;
                }
              }
            }
          }
        }
      }

      parent += 1;
    }

    return matches == 1;
  }

  /// Publishes resolved declarations, updates, and call holes after every body validates.
  public ResolvedLoopBodyPlan materializeResolvedLoopBodyProducts(
    borrow utf8 source,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    long callCount,
    borrow mut words callRows,
    borrow mut words bodyRows,
    borrow mut words nestedRows,
    borrow mut words statementPhysicalWidths
  ) {
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < LOOP_VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == LOOP_VALUE_ROWS);
    assert(-1 < callCount);
    assert(callCount < 257);
    assert(bufferLength(callRows) == 256);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(bufferLength(nestedRows) == NESTED_ROWS);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);

    region staging = new region(
      /* bytes= */ LOOP_BODY_RESOLUTION_ARENA_BYTES,
      /* allocations= */ 7
    );
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, BODY_ROWS);
    words stagedNestedRows = allocate(staging, NESTED_ROWS);
    words stagedPhysicalWidths = allocate(staging, MAX_STATEMENTS);
    words nextBodyLocals = allocate(staging, 64);
    long stagedStatement = 0;
    while (stagedStatement < statementCount) limit MAX_STATEMENTS {
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

    long bodyCount = 0;
    long nestedCount = 0;
    long failureStatement = -1;
    long processedStatementCount = 0;
    long priorStatementStart = -1;
    long rootOwner = -1;
    long rootBlock = -1;
    while (processedStatementCount < statementCount) limit MAX_STATEMENTS {
      long statement = nextLoopBodyStatement(
        priorStatementStart,
        statementCount,
        statementRows,
        LOOP_STATEMENT_START_ROW
      );
      if (statement == statementCount) {
        valid = false;
      } else {
        priorStatementStart = statementRows[LOOP_STATEMENT_START_ROW + statement];
      }

      boolean validBeforeStatement = valid;
      long childCount = statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement];
      long statementOwner = statementRows[statement];
      if (statementOwner != rootOwner) {
        rootOwner = statementOwner;
        rootBlock = loopBodyRootBlockForOwner(statementOwner, statementCount, statementRows);
      }

      if (rootBlock < statementRows[4096 + statement]) {
        boolean skipDirectConditionalChild = directConditionalChild(
          source,
          statement,
          statementCount,
          statementRows,
          rootBlock,
          semanticCount,
          tokenKinds,
          tokenStarts,
          tokenLengths
        );
        if (skipDirectConditionalChild == false) {
          if (childCount == 0) {
            long owner = statementRows[statement];
            long ordinal = statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement];
            long localBase = localBaseAtOrdinal(owner, ordinal, valueCount, valueRows);
            long selectedCall = callAtStatement(statement, callCount, callRows);
            if (selectedCall == -2) {
              valid = false;
            } else {
              if (-1 < selectedCall) {
                long callWidth = stagedPhysicalWidths[statement];
                if (callWidth < 0) {
                  valid = false;
                } else {
                  if (localBase < nextBodyLocals[owner]) {
                    localBase = nextBodyLocals[owner];
                  }

                  set(nextBodyLocals, owner, localBase + callWidth);
                }
              } else {
                DirectLoopBodyProduct product = resolveDirectLoopBodyProduct(
                  source,
                  owner,
                  ordinal,
                  statementRows[LOOP_STATEMENT_START_ROW + statement],
                  statementRows[LOOP_STATEMENT_LENGTH_ROW + statement],
                  nextBodyLocals[owner],
                  valueCount,
                  valueRows,
                  semanticCount,
                  tokenKinds,
                  tokenStarts,
                  tokenLengths
                );
                boolean statementValid = product.valid;
                localBase = product.localBase;
                long opcode = product.opcode;
                long operandKind = product.operandKind;
                long operand = product.operand;
                if (statementValid) {
                  set(stagedRows, bodyCount, statement);
                  set(stagedRows, BODY_LOCAL_BASE_ROW + bodyCount, localBase);
                  set(stagedRows, BODY_OPCODE_ROW + bodyCount, opcode);
                  set(stagedRows, BODY_OPERAND_KIND_ROW + bodyCount, operandKind);
                  set(stagedRows, BODY_OPERAND_ROW + bodyCount, operand);
                  long localCount = loopBodyLocalCount(opcode, operand);
                  if (localCount < 0) {
                    valid = false;
                  } else {
                    set(nextBodyLocals, owner, localBase + localCount);
                    set(stagedPhysicalWidths, statement, localCount);
                    bodyCount += 1;
                  }
                } else {
                  valid = false;
                }
              }
            }
          } else {
            long controlOwner = statementRows[statement];
            long controlOrdinal = statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement];
            long controlStart = statementRows[LOOP_STATEMENT_START_ROW + statement];
            long controlToken = tokenAtStart(controlStart, semanticCount, tokenStarts);
            if (controlToken < 0) {
              valid = false;
            } else {
              long controlHash = tokenHash(source, tokenStarts, tokenLengths, controlToken);
              if (controlHash == TOKEN_WHILE) {
                set(stagedPhysicalWidths, statement, 5);
              } else {
                if (controlHash != TOKEN_IF) {
                  valid = false;
                } else {
                  LoopNestedCondition control = resolveLoopNestedCondition(
                    source,
                    controlOwner,
                    controlOrdinal,
                    controlToken,
                    valueCount,
                    valueRows,
                    semanticCount,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths
                  );
                  if (control.valid == false) {
                    valid = false;
                  }

                  long controlLocalBase = localBaseAtOrdinal(
                    controlOwner,
                    controlOrdinal,
                    valueCount,
                    valueRows
                  );
                  if (controlLocalBase < nextBodyLocals[controlOwner]) {
                    controlLocalBase = nextBodyLocals[controlOwner];
                  }

                  if (255 < controlLocalBase + control.localCount) {
                    valid = false;
                  } else {
                    set(nextBodyLocals, controlOwner, controlLocalBase + control.localCount);
                    set(stagedNestedRows, nestedCount, statement);
                    set(stagedNestedRows, NESTED_KIND_ROW + nestedCount, control.kind);
                    set(
                      stagedNestedRows,
                      NESTED_CONDITION_LOCAL_ROW + nestedCount,
                      control.local
                    );
                    set(
                      stagedNestedRows,
                      NESTED_CONDITION_LITERAL_ROW + nestedCount,
                      control.literal
                    );
                    set(stagedNestedRows, NESTED_LOCAL_BASE_ROW + nestedCount, controlLocalBase);
                    set(stagedPhysicalWidths, statement, control.localCount);
                    nestedCount += 1;
                  }
                }
              }
            }
          }
        }
      }

      if (validBeforeStatement) {
        if (valid == false) {
          failureStatement = statement;
        }
      }

      processedStatementCount += 1;
    }

    if (valid) {
      long column = 0;
      while (column < 5) limit 5 {
        long bodyRow = 0;
        while (bodyRow < bodyCount) limit MAX_STATEMENTS {
          set(
            bodyRows,
            column * MAX_STATEMENTS + bodyRow,
            stagedRows[column * MAX_STATEMENTS + bodyRow]
          );
          bodyRow += 1;
        }

        column += 1;
      }

      column = 0;
      while (column < 5) limit 5 {
        long nestedRow = 0;
        while (nestedRow < nestedCount) limit MAX_STATEMENTS {
          set(
            nestedRows,
            column * MAX_STATEMENTS + nestedRow,
            stagedNestedRows[column * MAX_STATEMENTS + nestedRow]
          );
          nestedRow += 1;
        }

        column += 1;
      }

      long row = 0;
      while (row < statementCount) limit MAX_STATEMENTS {
        set(statementPhysicalWidths, row, stagedPhysicalWidths[row]);
        row += 1;
      }
    }

    drop(nextBodyLocals);
    drop(stagedPhysicalWidths);
    drop(stagedNestedRows);
    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new ResolvedLoopBodyPlan(0, 0, failureStatement, false);
    }

    return new ResolvedLoopBodyPlan(bodyCount, nestedCount, -1, true);
  }
}
