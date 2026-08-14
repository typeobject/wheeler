//! Applies one exactly invertible integer lifting transform.
classical class IntegerWaveletTransform {
  const long INPUT_HIGH = 10;
  const long INPUT_LOW = 6;
  const long TRANSFORMED_HIGH = INPUT_HIGH - INPUT_LOW;

  state long high = INPUT_HIGH;
  state long low = INPUT_LOW;
  state long observedHigh = 0;
  state long observedLow = 0;

  /// Maps one sample pair through a determinant-one lifting matrix.
  ///
  /// - Inverse: Reverses both lifting steps and restores the input samples exactly.
  rev void transformPair() {
    high -= INPUT_LOW;
    low += TRANSFORMED_HIGH;
  }

  /// Checks the generated inverse lifting transform.
  theorem transformInverse proves inverse(transformPair);

  /// Executes and reverses one integer wavelet pair.
  ///
  /// - Effects: Mutates only fixture state and restores both input samples.
  entry void main() {
    transformPair();
    observedHigh = high;
    observedLow = low;
    assert(observedHigh == 4);
    assert(observedLow == 10);

    reverse {
      transformPair();
    }

    assert(high == 10);
    assert(low == 6);
  }
}
