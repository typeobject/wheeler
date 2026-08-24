//! Locates exact scalar-helper names and attached inverse proofs.

module wheeler.compiler.helper_proofs;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class HelperProofs {
  /// Returns one helper name token, or minus one for a malformed header.
  public long helperNameToken(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long declaration,
    long closeToken
  ) {
    long cursor = declaration;
    while (cursor < closeToken) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_PAREN)
      ) {
        if (declaration < cursor) {
          if (tokenKinds[cursor - 1] == 1) {
            return cursor - 1;
          }
        }

        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_BRACE)
      ) {
        return -1;
      }

      cursor += 1;
    }

    return -1;
  }

  /// Checks whether one scalar-helper header declares reversible execution.
  public boolean helperReversible(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declaration
  ) {
    long modifier = declaration;
    long visibility = tokenHash(source, tokenStarts, tokenLengths, modifier);
    if (visibility == TOKEN_PUBLIC) {
      modifier += 1;
    } else {
      if (visibility == TOKEN_PRIVATE) {
        modifier += 1;
      }
    }

    return tokenHash(source, tokenStarts, tokenLengths, modifier) == TOKEN_REV;
  }

  /// Returns the token after one attached inverse proof.
  ///
  /// A declaration without a theorem returns `start`; a malformed theorem returns minus one.
  public long helperProofEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long start,
    long closeToken,
    long helperName
  ) {
    if (start == closeToken) {
      return start;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, start) == TOKEN_THEOREM) {} else {
      return start;
    }

    if (closeToken - start < 8) {
      return -1;
    }

    if (tokenKinds[start + 1] == 1) {} else {
      return -1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, start + 2) == TOKEN_PROVES) {} else {
      return -1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, start + 3) == TOKEN_INVERSE) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 4, PUNCTUATION_OPEN_PAREN)
    ) {} else {
      return -1;
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, helperName, start + 5) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 6, PUNCTUATION_CLOSE_PAREN)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 7, PUNCTUATION_SEMICOLON)
    ) {
      return start + 8;
    }

    return -1;
  }
}
