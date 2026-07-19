//! Explicit runtime-bound UTF-8 input; no ambient file or network access.
classical class HostInput {
  state long byteLength = 0;
  state long scalarCount = 0;
  state long firstScalar = 0;
  state long outputLength = 0;

  /// Runs the bounded `HostInput` fixture.
  ///
  /// - Effects: Mutates declared state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes output) {
    byteLength = bufferLength(source);
    scalarCount = utf8Count(source);
    firstScalar = utf8Scalar(source, 0);
    setByte(output, 0, firstScalar);
    setByte(output, 1, 33);
    outputLength = 2;
    setOutputLength(output, outputLength);
    assert(byteLength == 3);
    assert(scalarCount == 2);
    assert(firstScalar == 65);
    assert(outputLength == 2);
  }
}
