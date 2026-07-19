//! Parses the bounded Wheeler bootstrap source profile into IR.

module wheeler.compiler.parser;

import wheeler.compiler.helper_parser;
import wheeler.compiler.ir;
import wheeler.compiler.statements;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class Parser {

  private MinimalProgramResult minimalProgramValue(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstStart,
    long secondStart,
    long thirdStart,
    long fourthStart,
    long fifthStart
  ) {
    long initial = parsedSignedNumber(source, tokenStarts, tokenLengths, 8);
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, firstStart);
    long operand = sequenceStatementOperand(
      source,
      tokenStarts,
      tokenLengths,
      firstStart,
      -1,
      -1,
      -1,
      -1
    );
    long statementCount = 1;
    long secondOpcode = -1;
    long secondOperand = 0;
    long thirdOpcode = -1;
    long thirdOperand = 0;
    long fourthOpcode = -1;
    long fourthOperand = 0;
    long fifthOpcode = -1;
    long fifthOperand = 0;
    if (0 < secondStart) {
      statementCount = 2;
      secondOpcode = statementOpcode(source, tokenStarts, tokenLengths, secondStart);
      secondOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        secondStart,
        firstStart,
        -1,
        -1,
        -1
      );
    }

    if (0 < thirdStart) {
      statementCount = 3;
      thirdOpcode = statementOpcode(source, tokenStarts, tokenLengths, thirdStart);
      thirdOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        thirdStart,
        firstStart,
        secondStart,
        -1,
        -1
      );
    }

    if (0 < fourthStart) {
      statementCount = 4;
      fourthOpcode = statementOpcode(source, tokenStarts, tokenLengths, fourthStart);
      fourthOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        fourthStart,
        firstStart,
        secondStart,
        thirdStart,
        -1
      );
    }

    if (0 < fifthStart) {
      statementCount = 5;
      fifthOpcode = statementOpcode(source, tokenStarts, tokenLengths, fifthStart);
      fifthOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        fifthStart,
        firstStart,
        secondStart,
        thirdStart,
        fourthStart
      );
    }

    if (sequenceOperandValid(opcode, operand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(secondOpcode, secondOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(thirdOpcode, thirdOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(fourthOpcode, fourthOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(fifthOpcode, fifthOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(tokenStarts[6], tokenLengths[6]);
    SourceRange helper = new SourceRange(0, 0);
    MinimalProgram program = new MinimalProgram(
      name,
      global,
      1,
      initial,
      statementCount,
      opcode,
      operand,
      secondOpcode,
      secondOperand,
      thirdOpcode,
      thirdOperand,
      fourthOpcode,
      fourthOperand,
      fifthOpcode,
      fifthOperand,
      helper,
      0,
      -1,
      0,
      0,
      helper,
      0,
      0,
      0,
      0,
      -1,
      0,
      -1,
      0,
      -1,
      0
    );
    return new MinimalProgramResult.Value(program);
  }

  private MinimalProgramResult minimalEmptyProgramValue(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long initial = parsedSignedNumber(source, tokenStarts, tokenLengths, 8);
    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(tokenStarts[6], tokenLengths[6]);
    SourceRange helper = new SourceRange(0, 0);
    MinimalProgram program = new MinimalProgram(
      name,
      global,
      1,
      initial,
      0,
      -1,
      0,
      -1,
      0,
      -1,
      0,
      -1,
      0,
      -1,
      0,
      helper,
      0,
      -1,
      0,
      0,
      helper,
      0,
      0,
      0,
      0,
      -1,
      0,
      -1,
      0,
      -1,
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

  private MinimalProgramResult minimalNoGlobalValue(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstStart,
    long secondStart,
    long thirdStart,
    long fourthStart,
    long fifthStart
  ) {
    long statementCount = 0;
    long opcode = -1;
    long operand = 0;
    long secondOpcode = -1;
    long secondOperand = 0;
    long thirdOpcode = -1;
    long thirdOperand = 0;
    long fourthOpcode = -1;
    long fourthOperand = 0;
    long fifthOpcode = -1;
    long fifthOperand = 0;
    if (0 < firstStart) {
      statementCount = 1;
      opcode = statementOpcode(source, tokenStarts, tokenLengths, firstStart);
      operand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        firstStart,
        -1,
        -1,
        -1,
        -1
      );
    }

    if (0 < secondStart) {
      statementCount = 2;
      secondOpcode = statementOpcode(source, tokenStarts, tokenLengths, secondStart);
      secondOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        secondStart,
        firstStart,
        -1,
        -1,
        -1
      );
    }

    if (0 < thirdStart) {
      statementCount = 3;
      thirdOpcode = statementOpcode(source, tokenStarts, tokenLengths, thirdStart);
      thirdOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        thirdStart,
        firstStart,
        secondStart,
        -1,
        -1
      );
    }

    if (0 < fourthStart) {
      statementCount = 4;
      fourthOpcode = statementOpcode(source, tokenStarts, tokenLengths, fourthStart);
      fourthOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        fourthStart,
        firstStart,
        secondStart,
        thirdStart,
        -1
      );
    }

    if (0 < fifthStart) {
      statementCount = 5;
      fifthOpcode = statementOpcode(source, tokenStarts, tokenLengths, fifthStart);
      fifthOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        fifthStart,
        firstStart,
        secondStart,
        thirdStart,
        fourthStart
      );
    }

    if (sequenceOperandValid(opcode, operand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(secondOpcode, secondOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(thirdOpcode, thirdOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(fourthOpcode, fourthOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(fifthOpcode, fifthOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(0, 0);
    MinimalProgram program = new MinimalProgram(
      name,
      global,
      0,
      0,
      statementCount,
      opcode,
      operand,
      secondOpcode,
      secondOperand,
      thirdOpcode,
      thirdOperand,
      fourthOpcode,
      fourthOperand,
      fifthOpcode,
      fifthOperand,
      global,
      0,
      -1,
      0,
      0,
      global,
      0,
      0,
      0,
      0,
      -1,
      0,
      -1,
      0,
      -1,
      0
    );
    return new MinimalProgramResult.Value(program);
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

    if (
      noGlobalStatementSupported(source, tokenStarts, tokenLengths, statements.first) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      noGlobalStatementSupported(source, tokenStarts, tokenLengths, statements.second) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      noGlobalStatementSupported(source, tokenStarts, tokenLengths, statements.third) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      noGlobalStatementSupported(source, tokenStarts, tokenLengths, statements.fourth) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      noGlobalStatementSupported(source, tokenStarts, tokenLengths, statements.fifth) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    return minimalNoGlobalValue(
      source,
      tokenStarts,
      tokenLengths,
      statements.first,
      statements.second,
      statements.third,
      statements.fourth,
      statements.fifth
    );
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

  private record BodyStatements(
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    boolean valid
  ) {}

  private BodyStatements parseBodyStatements(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart,
    long count
  ) {
    if (bodyClosesAt(source, tokenKinds, tokenStarts, bodyStart, count)) {
      return new BodyStatements(-1, -1, -1, -1, -1, true);
    }

    long firstWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, bodyStart);
    if (firstWidth < 1) {
      return new BodyStatements(-1, -1, -1, -1, -1, false);
    }

    long firstEnd = bodyStart + firstWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, firstEnd, count)) {
      return new BodyStatements(bodyStart, -1, -1, -1, -1, true);
    }

    long secondWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, firstEnd);
    if (secondWidth < 1) {
      return new BodyStatements(bodyStart, firstEnd, -1, -1, -1, false);
    }

    long secondEnd = firstEnd + secondWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, secondEnd, count)) {
      return new BodyStatements(bodyStart, firstEnd, -1, -1, -1, true);
    }

    long thirdWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, secondEnd);
    if (thirdWidth < 1) {
      return new BodyStatements(bodyStart, firstEnd, secondEnd, -1, -1, false);
    }

    long thirdEnd = secondEnd + thirdWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, thirdEnd, count)) {
      return new BodyStatements(bodyStart, firstEnd, secondEnd, -1, -1, true);
    }

    long fourthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, thirdEnd);
    if (fourthWidth < 1) {
      return new BodyStatements(bodyStart, firstEnd, secondEnd, thirdEnd, -1, false);
    }

    long fourthEnd = thirdEnd + fourthWidth;
    if (bodyClosesAt(source, tokenKinds, tokenStarts, fourthEnd, count)) {
      return new BodyStatements(bodyStart, firstEnd, secondEnd, thirdEnd, -1, true);
    }

    long fifthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, fourthEnd);
    if (fifthWidth < 1) {
      return new BodyStatements(bodyStart, firstEnd, secondEnd, thirdEnd, fourthEnd, false);
    }

    long fifthEnd = fourthEnd + fifthWidth;
    boolean valid = bodyClosesAt(source, tokenKinds, tokenStarts, fifthEnd, count);
    return new BodyStatements(bodyStart, firstEnd, secondEnd, thirdEnd, fourthEnd, valid);
  }

  private boolean minimalStateCountSupported(long count) {
    if (17 < count) {
      return count < 128;
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
      if (count < 128) {
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
            if (statements.first < 0) {
              return minimalEmptyProgramValue(source, tokenStarts, tokenLengths);
            }

            return minimalProgramValue(
              source,
              tokenStarts,
              tokenLengths,
              statements.first,
              statements.second,
              statements.third,
              statements.fourth,
              statements.fifth
            );
          }
        }
      }
    }

    return new MinimalProgramResult.Error(0);
  }

}
