//! Builds bounded programs from resolved scalar-helper tables.

module wheeler.compiler.scalar_helper_programs;

import wheeler.compiler.body_parser;
import wheeler.compiler.class_layouts;
import wheeler.compiler.helper_call_sites;
import wheeler.compiler.ir;
import wheeler.compiler.scalar_helper_call_resolution;
import wheeler.compiler.scalar_helper_parsing;
import wheeler.compiler.scalar_helper_resolution;
import wheeler.compiler.sequences;
import wheeler.compiler.source_scalars;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class ScalarHelperPrograms {
  private MinimalProgramResult program(
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    ResolvedScalarHelperTable resolved,
    HelperBody entry,
    ClassLayout layout,
    boolean library
  ) {
    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange absent = new SourceRange(0, 0);
    SourceRange global = absent;
    if (layout.globalCount == 1) {
      global = new SourceRange(
        tokenStarts[layout.globalNameToken],
        tokenLengths[layout.globalNameToken]
      );
    }

    MinimalProgram result = new MinimalProgram(
      name,
      global,
      layout.globalCount,
      layout.initialValue,
      entry.statementCount,
      entry.opcodes,
      entry.operands,
      entry.secondaryOperands,
      entry.callStatements,
      entry.callFunctions,
      entry.callCount,
      resolved.helperCount,
      resolved.first,
      resolved.second,
      resolved.third,
      resolved.fourth,
      resolved.fifth,
      resolved.sixth,
      resolved.seventh,
      resolved.eighth,
      resolved.ninth,
      resolved.tenth,
      resolved.eleventh,
      resolved.twelfth,
      resolved.thirteenth,
      resolved.fourteenth,
      resolved.fifteenth,
      resolved.sixteenth,
      resolved.seventeenth,
      resolved.eighteenth,
      resolved.nineteenth,
      resolved.twentieth,
      resolved.twentyFirst,
      resolved.twentySecond,
      resolved.twentyThird,
      absent,
      0,
      0,
      0,
      library
    );
    return new MinimalProgramResult.Value(result);
  }

  private ResolvedHelperBody resolveEntryCalls(
    borrow utf8 source,
    HelperBody entry,
    ResolvedScalarHelperTable helpers
  ) {
    return resolvedHelperBody(
      source,
      entry,
      helpers.first,
      helpers.second,
      helpers.third,
      helpers.fourth,
      helpers.fifth,
      helpers.sixth,
      helpers.seventh,
      helpers.eighth,
      helpers.ninth,
      helpers.tenth,
      helpers.eleventh,
      helpers.twelfth,
      helpers.thirteenth,
      helpers.fourteenth,
      helpers.fifteenth,
      helpers.sixteenth,
      helpers.seventeenth,
      helpers.eighteenth,
      helpers.nineteenth,
      helpers.twentieth,
      helpers.twentyFirst,
      helpers.twentySecond,
      helpers.twentyThird,
      helpers.helperCount
    );
  }

  private ResolvedHelperBody resolveEntryBody(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long count,
    long entryStart,
    ResolvedScalarHelperTable helpers
  ) {
    long bodyStart = minimalBodyStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      entryStart
    );
    if (bodyStart < 1) {
      return new ResolvedHelperBody(emptyHelperBody(), false);
    }

    BodyScan statements = scanBody(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      bodyStart
    );
    if (statements.valid) {} else {
      return new ResolvedHelperBody(emptyHelperBody(), false);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statements.end, PUNCTUATION_CLOSE_BRACE)
    ) {} else {
      return new ResolvedHelperBody(emptyHelperBody(), false);
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statements.end + 1,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {} else {
      return new ResolvedHelperBody(emptyHelperBody(), false);
    }

    if (count == statements.end + 2) {} else {
      return new ResolvedHelperBody(emptyHelperBody(), false);
    }

    CallSites calls = collectCallSites(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      statements.count
    );
    if (calls.valid) {} else {
      return new ResolvedHelperBody(emptyHelperBody(), false);
    }

    StatementSequence sequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      statements.count
    );
    if (sequence.valid) {} else {
      return new ResolvedHelperBody(emptyHelperBody(), false);
    }

    HelperBody unresolvedEntry = new HelperBody(
      new SourceRange(0, 0),
      sequence.opcodes,
      sequence.operands,
      sequence.secondaryOperands,
      0,
      0,
      emptyHelperBody().parameterTypes,
      sequence.count,
      0,
      calls.targetStarts,
      calls.targetLengths,
      calls.statements,
      emptyHelperCallIdentities(),
      calls.count
    );
    return resolveEntryCalls(source, unresolvedEntry, helpers);
  }

  /// Builds one resolved program from one through twenty-three scalar helpers.
  public MinimalProgramResult parseScalarHelperLibrary(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long count,
    ClassLayout layout
  ) {
    ScalarHelperTable parsed = parseScalarHelpers(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      layout
    );
    ResolvedScalarHelperTable resolved = resolveScalarHelperTable(source, parsed);
    if (resolved.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, parsed.nextToken, PUNCTUATION_CLOSE_BRACE)
    ) {
      return program(tokenStarts, tokenLengths, resolved, emptyHelperBody(), layout, true);
    }

    ResolvedHelperBody entry = resolveEntryBody(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      parsed.nextToken,
      resolved
    );
    if (entry.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    return program(tokenStarts, tokenLengths, resolved, entry.body, layout, false);
  }
}
