//! Emits bounded canonical line records into caller-owned storage.

module wheeler.packages.line_emitter;

classical class LineEmitter {
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

  /// Emits `canonicalLines` into caller-owned bounded output.
  public long emitCanonicalLines(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    borrow mut bytes output
  ) {
    long token = 0;
    long cursor = 0;
    while (token < count) limit 32 {
      cursor = copyToken(source, starts[token], lengths[token], output, cursor);
      long scalar = utf8Scalar(source, starts[token]);
      if (scalar == 59) {
        setByte(output, cursor, 10);
        cursor += 1;
      } else {
        if (token + 1 < count) {
          long nextScalar = utf8Scalar(source, starts[token + 1]);
          if (nextScalar == 59) {
            cursor = cursor;
          } else {
            setByte(output, cursor, 32);
            cursor += 1;
          }
        }
      }

      token += 1;
    }

    return cursor;
  }
}
