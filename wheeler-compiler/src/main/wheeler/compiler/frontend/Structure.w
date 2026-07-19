//! Computes canonical section offsets for bootstrap artifacts.

module wheeler.compiler.structure;

import wheeler.compiler.tokens;

classical class Structure {
  private boolean canonicalMinimalNames(
    borrow mut words tokenKinds,
    borrow mut words tokenLengths
  ) {
    if (tokenKinds[2] == 1) {
      if (tokenLengths[2] < 257) {
        if (tokenKinds[6] == 1) {
          return tokenLengths[6] < 257;
        }
      }
    }

    return false;
  }

  /// Returns the first source offset of the bounded entry declaration.
  public long minimalEntryStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_CLASSICAL) {
      if (tokenHash(source, tokenStarts, tokenLengths, 1) == TOKEN_CLASS) {
        if (canonicalMinimalNames(tokenKinds, tokenLengths)) {
          if (
            punctuationAt(source, tokenKinds, tokenStarts, 3, PUNCTUATION_OPEN_BRACE)
          ) {
            if (tokenHash(source, tokenStarts, tokenLengths, 4) == TOKEN_STATE) {
              if (tokenHash(source, tokenStarts, tokenLengths, 5) == TOKEN_LONG) {
                if (
                  punctuationAt(source, tokenKinds, tokenStarts, 7, PUNCTUATION_ASSIGN)
                ) {
                  long width = signedNumberWidth(source, tokenKinds, tokenStarts, 8);
                  if (0 < width) {
                    if (signedNumberValid(source, tokenStarts, tokenLengths, 8)) {
                      long semicolon = 8 + width;
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          semicolon,
                          PUNCTUATION_SEMICOLON
                        )
                      ) {
                        return semicolon + 1;
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

  /// Returns the first source offset inside the bounded entry body.
  public long minimalBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long entryStart
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, entryStart) == TOKEN_ENTRY) {
      if (tokenHash(source, tokenStarts, tokenLengths, entryStart + 1) == TOKEN_VOID) {
        if (
          tokenHash(source, tokenStarts, tokenLengths, entryStart + 2) == TOKEN_MAIN
        ) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              entryStart + 3,
              PUNCTUATION_OPEN_PAREN
            )
          ) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                entryStart + 4,
                PUNCTUATION_CLOSE_PAREN
              )
            ) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  entryStart + 5,
                  PUNCTUATION_OPEN_BRACE
                )
              ) {
                return entryStart + 6;
              }
            }
          }
        }
      }
    }

    return -1;
  }
}
