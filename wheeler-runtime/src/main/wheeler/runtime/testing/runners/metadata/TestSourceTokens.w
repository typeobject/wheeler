//! Bounds token hashing used by native test discovery, metadata, and lowering.

module wheeler.runtime.testing.runners.test_source_tokens;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.tokens;

classical class TestSourceTokens {
  /// Returns one stable token hash or `-1` when its byte range exceeds the lexical profile.
  public long boundedSourceTokenHash(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    if (MAX_TOKEN_HASH_SCALARS < tokenLengths[token]) {
      return -1;
    }

    return tokenHash(source, tokenStarts, tokenLengths, token);
  }
}
