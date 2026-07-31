//! Copies one source selected by a bounded seven-module graph plan.

module wheeler.compiler.graphs.sources;

classical class BoundedGraphSources {
  private const long MAX_SOURCE_BYTES = 16384;

  private utf8 copySource(borrow utf8 source, borrow mut region arena) {
    long length = bufferLength(source);
    assert(0 < length);
    assert(length < MAX_SOURCE_BYTES + 1);
    bytes copied = allocateBytes(arena, length);
    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      setByte(copied, cursor, utf8Scalar(source, cursor));
      cursor += 1;
    }

    return freezeUtf8(copied);
  }

  /// Copies one of six selected sources into caller-owned bounded storage.
  public utf8 copySelectedSixSource(
    long index,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow mut region arena
  ) {
    if (index == 0) {
      return copySource(firstSource, arena);
    }

    if (index == 1) {
      return copySource(secondSource, arena);
    }

    if (index == 2) {
      return copySource(thirdSource, arena);
    }

    if (index == 3) {
      return copySource(fourthSource, arena);
    }

    if (index == 4) {
      return copySource(fifthSource, arena);
    }

    if (index == 5) {
      return copySource(sixthSource, arena);
    }

    assert(index == 0);
    return copySource(firstSource, arena);
  }

  /// Copies one of seven selected sources into caller-owned bounded storage.
  public utf8 copySelectedSevenSource(
    long index,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow mut region arena
  ) {
    if (index == 0) {
      return copySource(firstSource, arena);
    }

    if (index == 1) {
      return copySource(secondSource, arena);
    }

    if (index == 2) {
      return copySource(thirdSource, arena);
    }

    if (index == 3) {
      return copySource(fourthSource, arena);
    }

    if (index == 4) {
      return copySource(fifthSource, arena);
    }

    if (index == 5) {
      return copySource(sixthSource, arena);
    }

    if (index == 6) {
      return copySource(seventhSource, arena);
    }

    assert(index == 0);
    return copySource(firstSource, arena);
  }
}
