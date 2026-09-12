//! Resolves retained buffer types onto exact physical locals.

module wheeler.compiler.closure.direct_statement_coordinates;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.type_codes;

classical class DirectStatementCoordinates {
  /// Returns the exact retained type of one buffer value.
  public long directBufferLocalType(
    borrow utf8 source,
    long owner,
    long local,
    long valueCount,
    borrow mut words valueRows,
    long semanticCount,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long sourceType = loopBodyValueType(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      semanticCount,
      tokenStarts,
      tokenLengths
    );
    boolean borrowed = borrowedLoopBodyLocal(
      source,
      owner,
      local,
      valueCount,
      valueRows,
      semanticCount,
      tokenStarts,
      tokenLengths
    );
    if (sourceType == TOKEN_BYTEVIEW) {
      return TYPE_BYTE_VIEW;
    }

    if (sourceType == TOKEN_WORDS) {
      if (borrowed) {
        return TYPE_WORDS_BORROW;
      }

      return TYPE_WORDS;
    }

    if (sourceType == TOKEN_BYTES) {
      if (borrowed) {
        return TYPE_BYTES_BORROW;
      }

      return TYPE_BYTES;
    }

    if (sourceType == TOKEN_UTF8) {
      if (borrowed) {
        return TYPE_UTF8_BORROW;
      }

      return TYPE_UTF8;
    }

    return -1;
  }
}
