//! Parses the bounded Wheeler bootstrap source profile into IR.

module wheeler.compiler.parser;

import wheeler.compiler.helper_parser;
import wheeler.compiler.ir;
import wheeler.compiler.sequences;
import wheeler.compiler.statements;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class Parser {

  private MinimalProgramResult minimalProgramValue(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    StatementSequence statements,
    long globalCount
  ) {
    if (statements.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(0, 0);
    long initial = 0;
    if (globalCount == 1) {
      global = new SourceRange(tokenStarts[6], tokenLengths[6]);
      initial = parsedSignedNumber(source, tokenStarts, tokenLengths, 8);
    }

    SourceRange helper = new SourceRange(0, 0);
    MinimalProgram program = new MinimalProgram(
      name,
      global,
      globalCount,
      initial,
      statements.count,
      statements.opcodes,
      statements.operands,
      helper,
      0,
      new long[8](-1, -1, -1, -1, -1, -1, -1, -1),
      new long[8](0, 0, 0, 0, 0, 0, 0, 0),
      0,
      helper,
      0,
      0,
      0,
      0
    );
    return new MinimalProgramResult.Value(program);
  }

  private long minimalNoGlobalBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_CLASSICAL) {
      if (tokenHash(source, tokenStarts, tokenLengths, 1) == TOKEN_CLASS) {
        if (tokenKinds[2] == 1) {
          if (tokenLengths[2] < 257) {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, 3, PUNCTUATION_OPEN_BRACE)
            ) {
              if (tokenHash(source, tokenStarts, tokenLengths, 4) == TOKEN_ENTRY) {
                if (tokenHash(source, tokenStarts, tokenLengths, 5) == TOKEN_VOID) {
                  if (tokenHash(source, tokenStarts, tokenLengths, 6) == TOKEN_MAIN) {
                    if (
                      punctuationAt(source, tokenKinds, tokenStarts, 7, PUNCTUATION_OPEN_PAREN)
                    ) {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          8,
                          PUNCTUATION_CLOSE_PAREN
                        )
                      ) {
                        if (
                          punctuationAt(
                            source,
                            tokenKinds,
                            tokenStarts,
                            9,
                            PUNCTUATION_OPEN_BRACE
                          )
                        ) {
                          return 10;
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
    }

    return -1;
  }

  private boolean noGlobalStatementSupported(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (statementStart < 1) {
      return true;
    }

    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    boolean supported = opcode == STATEMENT_LOCAL_LONG;
    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      supported = true;
    }

    return supported;
  }

  private MinimalProgramResult minimalNoGlobalProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long bodyStart = minimalNoGlobalBodyStart(source, tokenKinds, tokenStarts, tokenLengths);
    if (bodyStart < 1) {
      return new MinimalProgramResult.Error(0);
    }

    BodyStatements statements = parseBodyStatements(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      bodyStart,
      count
    );
    if (statements.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    long statement = 0;
    while (statement < statements.count) limit 8 {
      if (
        noGlobalStatementSupported(
          source,
          tokenStarts,
          tokenLengths,
          statements.starts[statement]
        ) == false
      ) {
        return new MinimalProgramResult.Error(0);
      }

      statement += 1;
    }

    StatementSequence sequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      statements.starts,
      statements.count
    );
    return minimalProgramValue(source, tokenStarts, tokenLengths, sequence, 0);
  }

  private boolean bodyClosesAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementEnd,
    long count
  ) {
    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementEnd + 1,
          PUNCTUATION_CLOSE_BRACE
        )
      ) {
        return count == statementEnd + 2;
      }
    }

    return false;
  }

  private record BodyStatements(long count, long[8] starts, boolean valid) {}

  private BodyStatements parseBodyStatements(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart,
    long count
  ) {
    long[8] absent = new long[8](-1, -1, -1, -1, -1, -1, -1, -1);
    if (bodyClosesAt(source, tokenKinds, tokenStarts, bodyStart, count)) {
      return new BodyStatements(0, absent, true);
    }

    long firstWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, bodyStart);
    if (firstWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long firstEnd = bodyStart + firstWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, firstEnd, count)) {
      return new BodyStatements(1, new long[8](bodyStart, -1, -1, -1, -1, -1, -1, -1), true);
    }

    long secondWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, firstEnd);
    if (secondWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long secondEnd = firstEnd + secondWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, secondEnd, count)) {
      return new BodyStatements(
        2,
        new long[8](bodyStart, firstEnd, -1, -1, -1, -1, -1, -1),
        true
      );
    }

    long thirdWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, secondEnd);
    if (thirdWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long thirdEnd = secondEnd + thirdWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, thirdEnd, count)) {
      return new BodyStatements(
        3,
        new long[8](bodyStart, firstEnd, secondEnd, -1, -1, -1, -1, -1),
        true
      );
    }

    long fourthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, thirdEnd);
    if (fourthWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long fourthEnd = thirdEnd + fourthWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, fourthEnd, count)) {
      return new BodyStatements(
        4,
        new long[8](bodyStart, firstEnd, secondEnd, thirdEnd, -1, -1, -1, -1),
        true
      );
    }

    long fifthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, fourthEnd);
    if (fifthWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long fifthEnd = fourthEnd + fifthWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, fifthEnd, count)) {
      return new BodyStatements(
        5,
        new long[8](bodyStart, firstEnd, secondEnd, thirdEnd, fourthEnd, -1, -1, -1),
        true
      );
    }

    long sixthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, fifthEnd);
    if (sixthWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long sixthEnd = fifthEnd + sixthWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, sixthEnd, count)) {
      return new BodyStatements(
        6,
        new long[8](bodyStart, firstEnd, secondEnd, thirdEnd, fourthEnd, fifthEnd, -1, -1),
        true
      );
    }

    long seventhWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, sixthEnd);
    if (seventhWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long seventhEnd = sixthEnd + seventhWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, seventhEnd, count)) {
      return new BodyStatements(
        7,
        new long[8](
          bodyStart,
          firstEnd,
          secondEnd,
          thirdEnd,
          fourthEnd,
          fifthEnd,
          sixthEnd,
          -1
        ),
        true
      );
    }

    long eighthWidth = statementWidth(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      seventhEnd
    );
    if (eighthWidth < 1) {
      return new BodyStatements(0, absent, false);
    }

    long eighthEnd = seventhEnd + eighthWidth;
    long[8] starts = new long[8](
      bodyStart,
      firstEnd,
      secondEnd,
      thirdEnd,
      fourthEnd,
      fifthEnd,
      sixthEnd,
      seventhEnd
    );
    return new BodyStatements(
      8,
      starts,
      bodyClosesAt(source, tokenKinds, tokenStarts, eighthEnd, count)
    );
  }

  private boolean minimalStateCountSupported(long count) {
    if (17 < count) {
      return count < MAX_COMPILER_TOKENS;
    }

    return false;
  }

  /// Parses `minimalProgram` from a bounded canonical input.
  public MinimalProgramResult parseMinimalProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    if (10 < count) {
      if (count < MAX_COMPILER_TOKENS) {
        MinimalProgramResult noGlobal = minimalNoGlobalProgram(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          count
        );
        match (noGlobal) {
          case MinimalProgramResult.Value(MinimalProgram candidate) {
            return new MinimalProgramResult.Value(candidate);
          }
          case MinimalProgramResult.Error(long noGlobalOffset) {}
        }
      }
    }

    if (minimalStateCountSupported(count)) {
      long firstMember = minimalEntryStart(source, tokenKinds, tokenStarts, tokenLengths);
      if (0 < firstMember) {
        long firstMemberHash = tokenHash(source, tokenStarts, tokenLengths, firstMember);
        if (firstMemberHash == TOKEN_VOID) {
          return parseHelperProgram(source, tokenKinds, tokenStarts, tokenLengths, count);
        }

        if (firstMemberHash == TOKEN_REV) {
          return parseHelperProgram(source, tokenKinds, tokenStarts, tokenLengths, count);
        }
      }

      long entryStart = minimalEntryStart(source, tokenKinds, tokenStarts, tokenLengths);
      if (0 < entryStart) {
        long bodyStart = minimalBodyStart(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          entryStart
        );
        if (0 < bodyStart) {
          BodyStatements statements = parseBodyStatements(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            bodyStart,
            count
          );
          if (statements.valid) {
            StatementSequence sequence = parseStatementSequence(
              source,
              tokenStarts,
              tokenLengths,
              statements.starts,
              statements.count
            );
            return minimalProgramValue(source, tokenStarts, tokenLengths, sequence, 1);
          }
        }
      }
    }

    return new MinimalProgramResult.Error(0);
  }

}
