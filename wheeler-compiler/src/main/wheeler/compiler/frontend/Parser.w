//! Parses the bounded Wheeler bootstrap source profile into IR.

module wheeler.compiler.parser;

import wheeler.compiler.body_parser;
import wheeler.compiler.helper_parser;
import wheeler.compiler.ir;
import wheeler.compiler.sequences;
import wheeler.compiler.statement_forms;
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
      statements.secondaryOperands,
      helper,
      0,
      emptyStatementOpcodes(),
      emptyStatementOperands(),
      emptyStatementOperands(),
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
    long memberStart = minimalNoGlobalMemberStart(source, tokenKinds, tokenStarts, tokenLengths);
    if (memberStart < 1) {
      return -1;
    }

    return minimalBodyStart(source, tokenKinds, tokenStarts, tokenLengths, memberStart);
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
    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_ADD_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_XOR_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_AND_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_AND_LOCALS_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MUL_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_DIV_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MOD_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      supported = true;
    }

    return supported;
  }

  private MinimalProgramResult minimalNoGlobalProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long count
  ) {
    long bodyStart = minimalNoGlobalBodyStart(source, tokenKinds, tokenStarts, tokenLengths);
    if (bodyStart < 1) {
      return new MinimalProgramResult.Error(0);
    }

    BodyScan statements = scanBody(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      bodyStart
    );
    if (statements.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      bodyClosesAt(source, tokenKinds, tokenStarts, statements.end, count) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    long statement = 0;
    while (statement < statements.count) limit MAX_MINIMAL_STATEMENTS {
      if (
        noGlobalStatementSupported(
          source,
          tokenStarts,
          tokenLengths,
          statementStarts[statement]
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
      statementStarts,
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
    borrow mut words statementStarts,
    long count
  ) {
    if (10 < count) {
      if (count < MAX_COMPILER_TOKENS) {
        MinimalProgramResult noGlobal = minimalNoGlobalProgram(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          statementStarts,
          count
        );
        match (noGlobal) {
          case MinimalProgramResult.Value(MinimalProgram candidate) {
            return new MinimalProgramResult.Value(candidate);
          }
          case MinimalProgramResult.Error(long noGlobalOffset) {}
        }

        MinimalProgramResult helper = parseHelperProgram(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          statementStarts,
          count
        );
        match (helper) {
          case MinimalProgramResult.Value(MinimalProgram helperCandidate) {
            return new MinimalProgramResult.Value(helperCandidate);
          }
          case MinimalProgramResult.Error(long helperOffset) {}
        }
      }
    }

    if (minimalStateCountSupported(count)) {
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
          BodyScan statements = scanBody(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            statementStarts,
            bodyStart
          );
          if (statements.valid) {
            if (bodyClosesAt(source, tokenKinds, tokenStarts, statements.end, count)) {
              StatementSequence sequence = parseStatementSequence(
                source,
                tokenStarts,
                tokenLengths,
                statementStarts,
                statements.count
              );
              return minimalProgramValue(source, tokenStarts, tokenLengths, sequence, 1);
            }
          }
        }
      }
    }

    return new MinimalProgramResult.Error(0);
  }

}
