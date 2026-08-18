//! Validates bounded unqualified void-call source forms.

module wheeler.compiler.void_call_syntax;

import wheeler.compiler.source_scalars;
import wheeler.compiler.void_call_source_forms;

classical class VoidCallSyntax {
  private long wordAt(borrow mut words values, long index) {
    long selected = values[index];
    return selected;
  }

  private boolean punctuationAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long scalar
  ) {
    long kind = wordAt(tokenKinds, token);
    boolean kindValid = kind == 3;
    if (kindValid == false) {
      return false;
    }

    long start = wordAt(tokenStarts, token);
    long actual = utf8Scalar(source, start);
    return actual == scalar;
  }

  private long separatorEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long cursor,
    long argument,
    long arity
  ) {
    if (argument == arity) {
      return cursor;
    }

    long commaPunctuation = PUNCTUATION_COMMA;
    boolean commaValid = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      cursor,
      commaPunctuation
    );
    if (commaValid == false) {
      return -1;
    }

    return cursor + 1;
  }

  private long argumentEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long cursor,
    long argument,
    long arity
  ) {
    if (argument == arity) {
      return cursor;
    }

    long argumentKind = wordAt(tokenKinds, cursor);
    boolean argumentValid = argumentKind == 1;
    if (argumentValid == false) {
      return -1;
    }

    long nextCursor = cursor + 1;
    long nextArgument = argument + 1;
    long separatedCursor = separatorEnd(
      source,
      tokenKinds,
      tokenStarts,
      nextCursor,
      nextArgument,
      arity
    );
    if (separatedCursor < 0) {
      return -1;
    }

    return argumentEnd(source, tokenKinds, tokenStarts, separatedCursor, nextArgument, arity);
  }

  /// Validates and sizes one source void-call statement.
  public long voidCallStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long kind
  ) {
    long arity = voidCallSourceArity(kind);
    long openPunctuation = PUNCTUATION_OPEN_PAREN;
    long closePunctuation = PUNCTUATION_CLOSE_PAREN;
    long semicolonPunctuation = PUNCTUATION_SEMICOLON;
    if (arity < 0) {
      return -1;
    }

    long firstKind = wordAt(tokenKinds, statementStart);
    boolean firstValid = firstKind == 1;
    if (firstValid == false) {
      return -1;
    }

    long openToken = statementStart + 1;
    boolean openValid = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      openToken,
      openPunctuation
    );
    if (openValid == false) {
      return -1;
    }

    long firstArgument = statementStart + 2;
    long firstArgumentIndex = 0;
    long cursor = argumentEnd(
      source,
      tokenKinds,
      tokenStarts,
      firstArgument,
      firstArgumentIndex,
      arity
    );
    if (cursor < 0) {
      return -1;
    }

    boolean closeValid = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      cursor,
      closePunctuation
    );
    if (closeValid == false) {
      return -1;
    }

    long semicolonToken = cursor + 1;
    boolean semicolonValid = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      semicolonToken,
      semicolonPunctuation
    );
    if (semicolonValid == false) {
      return -1;
    }

    long width = cursor - statementStart;
    return width + 2;
  }
}
