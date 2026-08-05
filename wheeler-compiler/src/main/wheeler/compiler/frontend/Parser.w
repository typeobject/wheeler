//! Parses the bounded Wheeler bootstrap source profile into IR.

module wheeler.compiler.parser;

import wheeler.compiler.body_parser;
import wheeler.compiler.class_constants;
import wheeler.compiler.class_layouts;
import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.helper_parser;
import wheeler.compiler.ir;
import wheeler.compiler.named_local_assignment_kinds;
import wheeler.compiler.named_local_update_kinds;
import wheeler.compiler.scalar_helper_libraries;
import wheeler.compiler.sequences;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.statements;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class Parser {

  private MinimalProgramResult minimalProgramValue(
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    StatementSequence statements,
    ClassLayout layout,
    boolean library
  ) {
    if (statements.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(0, 0);
    if (layout.globalCount == 1) {
      global = new SourceRange(
        tokenStarts[layout.globalNameToken],
        tokenLengths[layout.globalNameToken]
      );
    }

    SourceRange helper = new SourceRange(0, 0);
    MinimalProgram program = new MinimalProgram(
      name,
      global,
      layout.globalCount,
      layout.initialValue,
      statements.count,
      statements.opcodes,
      statements.operands,
      statements.secondaryOperands,
      0,
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      helper,
      0,
      0,
      0,
      library
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

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      supported = true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
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

    if (localUpdateSourceStatement(opcode)) {
      supported = true;
    }

    if (localAssignmentSourceStatement(opcode)) {
      supported = true;
    }

    if (opcode == STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED) {
      supported = true;
    }

    return supported;
  }

  private MinimalProgramResult minimalEntryProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long count,
    ClassLayout layout
  ) {
    if (
      classConstantNameExists(source, tokenStarts, tokenLengths, layout.memberStart + 2)
    ) {
      return new MinimalProgramResult.Error(0);
    }

    long bodyStart = minimalBodyStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      layout.memberStart
    );
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

    if (layout.globalCount == 0) {
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
    }

    StatementSequence sequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      statements.count
    );
    return minimalProgramValue(tokenStarts, tokenLengths, sequence, layout, false);
  }

  private MinimalProgramResult constantOnlyLibrary(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count,
    ClassLayout layout
  ) {
    if (layout.globalCount == 0) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (layout.memberStart + 1 == count) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        layout.memberStart,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {} else {
      return new MinimalProgramResult.Error(0);
    }

    StatementSequence empty = new StatementSequence(
      0,
      emptyStatementOpcodes(),
      emptyStatementOperands(),
      emptyStatementOperands(),
      true
    );
    return minimalProgramValue(tokenStarts, tokenLengths, empty, layout, true);
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
        ClassLayout layout = resolveClassLayout(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          count
        );
        if (layout.valid) {
          MinimalProgramResult library = constantOnlyLibrary(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            count,
            layout
          );
          match (library) {
            case MinimalProgramResult.Value(MinimalProgram libraryCandidate) {
              return new MinimalProgramResult.Value(libraryCandidate);
            }
            case MinimalProgramResult.Error(long libraryOffset) {}
          }

          MinimalProgramResult scalarHelpers = parseScalarHelperLibrary(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            statementStarts,
            count,
            layout
          );
          match (scalarHelpers) {
            case MinimalProgramResult.Value(MinimalProgram scalarHelperCandidate) {
              return new MinimalProgramResult.Value(scalarHelperCandidate);
            }
            case MinimalProgramResult.Error(long scalarHelperOffset) {}
          }

          MinimalProgramResult entry = minimalEntryProgram(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            statementStarts,
            count,
            layout
          );
          match (entry) {
            case MinimalProgramResult.Value(MinimalProgram candidate) {
              return new MinimalProgramResult.Value(candidate);
            }
            case MinimalProgramResult.Error(long entryOffset) {}
          }

          MinimalProgramResult helper = parseHelperProgram(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            statementStarts,
            count,
            layout
          );
          match (helper) {
            case MinimalProgramResult.Value(MinimalProgram helperCandidate) {
              return new MinimalProgramResult.Value(helperCandidate);
            }
            case MinimalProgramResult.Error(long helperOffset) {}
          }
        }
      }
    }

    return new MinimalProgramResult.Error(0);
  }

}
