//! Checks source value bindings without treating every vocabulary word as reserved.

module wheeler.compiler.source_member_names;

import wheeler.compiler.keyword_tokens;
import wheeler.compiler.tokens;

classical class SourceMemberNames {
  /// Admits a scanner-owned value name except for the five language-reserved values.
  /// Type names, field labels, and proof names have separate binding rules.
  public boolean sourceValueNameValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    if (token < 0) {
      return false;
    }

    if (bufferLength(kinds) - 1 < token) {
      return false;
    }

    if (bufferLength(starts) - 1 < token) {
      return false;
    }

    if (bufferLength(lengths) - 1 < token) {
      return false;
    }

    if (kinds[token] != 1) {
      return false;
    }

    long code = sourceTokenCode(source, starts, lengths, token);
    if (code == TOKEN_DONE_VALUE) {
      return false;
    }

    if (code == TOKEN_NIL) {
      return false;
    }

    if (code == TOKEN_NONE) {
      return false;
    }

    if (code == TOKEN_NULL) {
      return false;
    }

    return code != TOKEN_UNDEFINED;
  }
}
