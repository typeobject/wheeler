//! Copies validated canonical-YAML line documents into caller-owned output.

module wheeler.packages.line_emitter;

classical class LineEmitter {
  /// Emits canonical bytes without inventing whitespace from a bounded semantic view.
  public long emitCanonicalLines(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    borrow mut bytes output
  ) {
    long cursor = 0;
    long sourceLength = bufferLength(source);
    while (cursor < sourceLength) limit 4096 {
      setByte(output, cursor, utf8Scalar(source, cursor));
      cursor += utf8Width(source, cursor);
    }

    return cursor;
  }
}
