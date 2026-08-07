//! Classifies unqualified named void calls by exact source arity.

module wheeler.compiler.void_call_source_syntax;

import wheeler.compiler.identifier_starts;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_forms;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallSourceSyntax {
  /// Returns the unresolved void-call identity for one token sequence.
  public long namedVoidCallKind(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    long cursor = statementStart + 2;
    if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_CLOSE_PAREN) {
      return STATEMENT_CALL_VOID_ZERO_NAMED;
    }

    long arity = 0;
    while (arity < MAX_VOID_CALL_ARGUMENTS) limit MAX_VOID_CALL_ARGUMENTS {
      if (identifierStart(utf8Scalar(source, tokenStarts[cursor]))) {} else {
        return -1;
      }

      arity += 1;
      cursor += 1;
      long separator = utf8Scalar(source, tokenStarts[cursor]);
      if (separator == PUNCTUATION_CLOSE_PAREN) {
        return voidCallSourceKind(arity);
      }

      if (separator == PUNCTUATION_COMMA) {} else {
        return -1;
      }

      cursor += 1;
    }

    return voidCallSourceKind(arity);
  }
}
