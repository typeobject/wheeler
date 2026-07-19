//! Emits bounded canonical package manifests.

module wheeler.packages.emitter;

classical class ManifestEmitter {
  private boolean semicolonToken(borrow utf8 source, borrow mut words starts, long token) {
    return utf8Scalar(source, starts[token]) == 59;
  }

  private long copyToken(
    borrow utf8 source,
    long start,
    long length,
    borrow mut bytes output,
    long outputCursor
  ) {
    long sourceCursor = start;
    long sourceEnd = start + length;
    long cursor = outputCursor;
    while (sourceCursor < sourceEnd) limit 256 {
      setByte(output, cursor, utf8Scalar(source, sourceCursor));
      cursor += 1;
      sourceCursor += utf8Width(source, sourceCursor);
    }

    return cursor;
  }

  /// Emits `canonical` into caller-owned bounded output.
  public long emitCanonical(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    borrow mut bytes output
  ) {
    long token = 0;
    long cursor = 0;
    while (token < count) limit 64 {
      cursor = copyToken(source, starts[token], lengths[token], output, cursor);
      long next = token + 1;
      if (next < count) {
        boolean beforeSemicolon = semicolonToken(source, starts, next);
        if (beforeSemicolon) {
          cursor += 0;
        } else {
          setByte(output, cursor, 32);
          cursor += 1;
        }
      }

      token += 1;
    }

    return cursor;
  }
}
