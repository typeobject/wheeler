//! Validates bounded unqualified void-call source forms.

module wheeler.compiler.void_call_syntax;

import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallSyntax {
  /// Validates and sizes one source void-call statement.
  public long voidCallStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long kind
  ) {
    if (voidCallSourceStatement(kind)) {} else {
      return -1;
    }

    if (tokenKinds[statementStart] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      )
    ) {} else {
      return -1;
    }

    if (kind == STATEMENT_CALL_VOID_ZERO_NAMED) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 2,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 3,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 4;
      }

      return -1;
    }

    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    if (kind == STATEMENT_CALL_VOID_ONE_NAMED) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 3,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 5;
      }

      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 4] == 1) {} else {
      return -1;
    }

    if (kind == STATEMENT_CALL_VOID_THREE_NAMED) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 5, PUNCTUATION_COMMA)
      ) {} else {
        return -1;
      }

      if (tokenKinds[statementStart + 6] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 7,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 8,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 9;
      }

      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 5,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 6, PUNCTUATION_SEMICOLON)
    ) {
      return 7;
    }

    return -1;
  }
}
