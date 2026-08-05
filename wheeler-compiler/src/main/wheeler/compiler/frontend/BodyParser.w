//! Scans bounded function bodies into caller-owned statement tables.

module wheeler.compiler.body_parser;

import wheeler.compiler.compiler_program_limits;
import wheeler.compiler.ir;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statements;
import wheeler.compiler.tokens;

classical class BodyParser {
  /// Describes one body scan without lending the caller-owned start table.
  public record BodyScan(long end, long count, boolean valid) {}

  /// Finds zero through sixty-four statements ending at one closing brace.
  public BodyScan scanBody(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long bodyStart
  ) {
    long cursor = bodyStart;
    long count = 0;
    while (count < MAX_MINIMAL_STATEMENTS) limit MAX_MINIMAL_STATEMENTS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_BRACE)
      ) {
        return new BodyScan(cursor, count, true);
      }

      long width = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, cursor);
      if (width < 1) {
        return new BodyScan(cursor, count, false);
      }

      set(statementStarts, count, cursor);
      cursor += width;
      count += 1;
    }

    boolean closes = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      cursor,
      PUNCTUATION_CLOSE_BRACE
    );
    return new BodyScan(cursor, count, closes);
  }
}
