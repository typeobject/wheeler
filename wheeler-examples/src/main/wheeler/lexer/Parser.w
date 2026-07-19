//! Recognizes bounded declarations over scanner metadata.

module examples.lexer.parser;

import wheeler.lexer.scanner;

classical class Parser {
  /// Defines the closed `DeclarationResult` cases exported by this module.
  public variant DeclarationResult {
    case Value(long value);
    case Error(long offset);
  }

  private boolean punctuationAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long scalar
  ) {
    if (tokenKinds[token] == 3) {
      return utf8Scalar(source, tokenStarts[token]) == scalar;
    }

    return false;
  }

  private boolean isLongKeyword(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (tokenLengths[0] == 4) {
      long start = tokenStarts[0];
      if (utf8Scalar(source, start) == 108) {
        if (utf8Scalar(source, start + 1) == 111) {
          if (utf8Scalar(source, start + 2) == 110) {
            return utf8Scalar(source, start + 3) == 103;
          }
        }
      }
    }

    return false;
  }

  /// Parses `declaration` from a bounded canonical input.
  public DeclarationResult parseDeclaration(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    if (count == 6) {
      if (isLongKeyword(source, tokenStarts, tokenLengths)) {
        if (tokenKinds[1] == 1) {
          if (punctuationAt(source, tokenKinds, tokenStarts, 2, 61)) {
            if (tokenKinds[3] == 2) {
              if (punctuationAt(source, tokenKinds, tokenStarts, 4, 59)) {
                if (3 < tokenKinds[5]) {
                  if (tokenKinds[5] < 6) {
                    long end = tokenStarts[3] + tokenLengths[3];
                    long value = parseNumber(source, tokenStarts[3], end);
                    if (value < 0) {
                      return new DeclarationResult.Error(tokenStarts[3]);
                    }

                    return new DeclarationResult.Value(value);
                  }
                }
              }
            }
          }
        }
      }
    }

    return new DeclarationResult.Error(0);
  }
}
