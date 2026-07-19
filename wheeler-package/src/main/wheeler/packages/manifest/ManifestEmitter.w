//! Copies one validated canonical-YAML package manifest into caller-owned output.

module wheeler.packages.emitter;

classical class ManifestEmitter {
  /// Emits canonical bytes without rebuilding YAML from a lossy bounded model.
  public long emitCanonical(
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
