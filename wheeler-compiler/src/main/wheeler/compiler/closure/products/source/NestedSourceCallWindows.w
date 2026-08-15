//! Resolves and copies source-call windows owned by structured control products.

module wheeler.compiler.closure.nested_source_call_windows;

classical class NestedSourceCallWindows {
  private const long CALL_COUNT_LIMIT = 256;
  private const long MAX_CODE_BYTES = 262144;

  /// Identifies one exact call and its canonical instruction and code extent.
  public record NestedSourceCallWindow(
    long call,
    long instructionCount,
    long length,
    boolean valid
  ) {}

  /// Resolves one source statement to one exact retained call window.
  public NestedSourceCallWindow resolveNestedSourceCallWindow(
    long statement,
    long callCount,
    borrow mut words callStatements,
    borrow mut words callWindowRows
  ) {
    assert(-1 < statement);
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callWindowRows) == 768);

    long selected = -1;
    long matches = 0;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      if (callStatements[call] == statement) {
        selected = call;
        matches += 1;
      }

      call += 1;
    }

    if (matches != 1) {
      return new NestedSourceCallWindow(0, 0, 0, false);
    }

    long instructionCount = callWindowRows[256 + selected];
    long length = callWindowRows[512 + selected];
    long start = callWindowRows[selected];
    if (instructionCount < 1) {
      return new NestedSourceCallWindow(0, 0, 0, false);
    }

    if (length < 1) {
      return new NestedSourceCallWindow(0, 0, 0, false);
    }

    if (start < 0) {
      return new NestedSourceCallWindow(0, 0, 0, false);
    }

    if (MAX_CODE_BYTES - length < start) {
      return new NestedSourceCallWindow(0, 0, 0, false);
    }

    return new NestedSourceCallWindow(selected, instructionCount, length, true);
  }

  /// Copies one complete retained call extent into its enclosing code window.
  public long writeNestedSourceCallWindow(
    long call,
    borrow mut words callWindowRows,
    borrow byteview callCode,
    long outputStart,
    borrow mut bytes output
  ) {
    assert(-1 < call);
    assert(call < CALL_COUNT_LIMIT);
    assert(bufferLength(callWindowRows) == 768);
    assert(bufferLength(callCode) == MAX_CODE_BYTES);
    assert(-1 < outputStart);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    long sourceStart = callWindowRows[call];
    long length = callWindowRows[512 + call];
    if (sourceStart < 0) {
      return -1;
    }

    if (length < 1) {
      return -1;
    }

    if (MAX_CODE_BYTES - length < sourceStart) {
      return -1;
    }

    if (MAX_CODE_BYTES - length < outputStart) {
      return -1;
    }

    long offset = 0;
    while (offset < length) limit MAX_CODE_BYTES {
      setByte(output, outputStart + offset, callCode[sourceStart + offset]);
      offset += 1;
    }

    return outputStart + length;
  }
}
