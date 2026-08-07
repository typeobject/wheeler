//! Copies one source selected by a canonical bounded seven-module graph plan.

module wheeler.compiler.graphs.sources;

classical class BoundedGraphSources {
  private const long MAX_SOURCE_BYTES = 16384;
  private const long SOURCE_BYTE_LIMIT = 16385;
  /// Names a two-source graph frame.
  public const long GRAPH_SOURCE_COUNT_TWO = 2;
  /// Names a three-source graph frame.
  public const long GRAPH_SOURCE_COUNT_THREE = 3;
  /// Names a four-source graph frame.
  public const long GRAPH_SOURCE_COUNT_FOUR = 4;
  /// Names a five-source graph frame.
  public const long GRAPH_SOURCE_COUNT_FIVE = 5;
  /// Names a six-source graph frame.
  public const long GRAPH_SOURCE_COUNT_SIX = 6;
  /// Names the largest admitted graph frame.
  public const long GRAPH_SOURCE_COUNT_SEVEN = 7;
  private const long GRAPH_SOURCE_COUNT_LIMIT = 8;

  private utf8 copySource(borrow utf8 source, borrow mut region arena) {
    long length = bufferLength(source);
    assert(length < SOURCE_BYTE_LIMIT);
    long cursor = 0;
    bytes copied = allocateBytes(arena, length);
    while (cursor < length) limit MAX_SOURCE_BYTES {
      setByte(copied, cursor, utf8Scalar(source, cursor));
      cursor += 1;
    }

    return freezeUtf8(copied);
  }

  /// Copies one validated source into caller-owned bounded storage.
  public utf8 copySelectedSource(
    long index,
    long sourceCount,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow mut region arena
  ) {
    assert(sourceCount < GRAPH_SOURCE_COUNT_LIMIT);
    assert(index < sourceCount);

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
