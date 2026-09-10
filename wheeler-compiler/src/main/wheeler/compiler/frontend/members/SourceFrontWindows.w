//! Checks source front coordinates before any scanner-column read.

module wheeler.compiler.source_front_windows;

import wheeler.compiler.compiler_token_limits;

classical class SourceFrontWindows {
  /// Admits one nonempty token window in the existing bounded source profile.
  /// The semantic scanner owns token kinds and source byte ranges.
  public boolean sourceFrontWindowValid(
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long start
  ) {
    if (start < 0) {
      return false;
    }

    if (count < 1) {
      return false;
    }

    if (count - 1 < start) {
      return false;
    }

    if (MAX_COMPILER_TOKENS < count) {
      return false;
    }

    if (bufferLength(kinds) < count) {
      return false;
    }

    if (bufferLength(starts) < count) {
      return false;
    }

    return count < bufferLength(lengths) + 1;
  }
}
