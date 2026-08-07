//! Validates bounded unqualified void-call source forms.

module wheeler.compiler.void_call_syntax;

import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_forms;
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
    long arity = voidCallSourceArity(kind);
    if (arity < 0) {
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

    long argument = 0;
    long cursor = statementStart + 2;
    while (argument < arity) limit MAX_VOID_CALL_ARGUMENTS {
      if (tokenKinds[cursor] == 1) {} else {
        return -1;
      }

      cursor += 1;
      argument += 1;
      if (argument < arity) {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_COMMA)
        ) {} else {
          return -1;
        }

        cursor += 1;
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, cursor + 1, PUNCTUATION_SEMICOLON)
    ) {
      return cursor - statementStart + 2;
    }

    return -1;
  }
}
