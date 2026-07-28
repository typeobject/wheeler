//! Computes canonical section offsets for bootstrap artifacts.

module wheeler.compiler.structure;

import wheeler.compiler.tokens;

classical class Structure {
  private boolean canonicalClassName(borrow mut words tokenKinds, borrow mut words tokenLengths) {
    if (tokenKinds[2] == 1) {
      return tokenLengths[2] < 257;
    }

    return false;
  }

  private boolean canonicalMinimalNames(
    borrow mut words tokenKinds,
    borrow mut words tokenLengths
  ) {
    if (canonicalClassName(tokenKinds, tokenLengths)) {
      if (tokenKinds[6] == 1) {
        return tokenLengths[6] < 257;
      }
    }

    return false;
  }

  /// Returns the first member token of a no-state bounded class.
  public long minimalNoGlobalMemberStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, 0) == TOKEN_CLASSICAL) {
      if (tokenHash(source, tokenStarts, tokenLengths, 1) == TOKEN_CLASS) {
        if (canonicalClassName(tokenKinds, tokenLengths)) {
          if (
            punctuationAt(source, tokenKinds, tokenStarts, 3, PUNCTUATION_OPEN_BRACE)
          ) {
            return 4;
          }
        }
      }
    }

    return -1;
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

  /// Validates and sizes one bounded helper value statement.
  public long helperValueStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (statementKind == STATEMENT_RETURN_LONG) {
      long returnWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 1);
      if (returnWidth < 1) {
        return -1;
      }

      if (
        signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 1) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 1 + returnWidth,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return returnWidth + 2;
      }

      return -1;
    }

    if (statementKind == STATEMENT_RETURN_LOCAL_NAMED) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 2,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 3;
      }

      return -1;
    }

    if (statementKind == STATEMENT_LOCAL_CALL_NAMED) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 5,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 6,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 7;
      }
    }

    if (statementKind == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        ) == false
      ) {
        return -1;
      }

      long argumentWidth = signedNumberWidth(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 5
      );
      if (argumentWidth < 1) {
        return -1;
      }

      if (
        signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 5 + argumentWidth,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 6 + argumentWidth,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return argumentWidth + 7;
      }
    }

    return -1;
  }

  /// Validates and sizes one equality assertion over two signed literals.
  public long literalEqualityStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      ) == false
    ) {
      return -1;
    }

    long leftWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 2);
    if (leftWidth < 1) {
      return -1;
    }

    if (
      signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 2) == false
    ) {
      return -1;
    }

    long equalityStart = statementStart + 2 + leftWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, equalityStart, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, equalityStart + 1, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long rightStart = equalityStart + 2;
    long rightWidth = signedNumberWidth(source, tokenKinds, tokenStarts, rightStart);
    if (rightWidth < 1) {
      return -1;
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, rightStart) == false) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        rightStart + rightWidth,
        PUNCTUATION_CLOSE_PAREN
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        rightStart + rightWidth + 1,
        PUNCTUATION_SEMICOLON
      )
    ) {
      return rightStart + rightWidth + 2 - statementStart;
    }

    return -1;
  }

}
