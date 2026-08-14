//! Applies an exactly invertible integer lifting transform to one two-pair tile.
classical class IntegerWaveletTransform {
  const long FIRST_HIGH = 10;
  const long FIRST_LOW = 6;
  const long FIRST_COEFFICIENT = FIRST_HIGH - FIRST_LOW;
  const long SECOND_HIGH = 21;
  const long SECOND_LOW = 13;
  const long SECOND_COEFFICIENT = SECOND_HIGH - SECOND_LOW;

  state long high = FIRST_HIGH;
  state long low = FIRST_LOW;
  state long highSecond = SECOND_HIGH;
  state long lowSecond = SECOND_LOW;
  state long observedHigh = 0;
  state long observedLow = 0;
  state long observedHighSecond = 0;
  state long observedLowSecond = 0;
  state long generatedCases = 0;

  long highCoefficient(long left, long right) {
    return left - right;
  }

  long lowCoefficient(long right, long difference) {
    return right + difference;
  }

  /// Maps two sample pairs through determinant-one integer lifting steps.
  ///
  /// - Inverse: Reverses all lifting steps and restores the tile exactly.
  rev void transformTile() {
    high -= FIRST_LOW;
    low += FIRST_COEFFICIENT;
    highSecond -= SECOND_LOW;
    lowSecond += SECOND_COEFFICIENT;
  }

  /// Checks the generated inverse lifting transform.
  theorem transformInverse proves inverse(transformTile);

  /// Exhausts a bounded coefficient domain and reverses one encoded tile.
  ///
  /// - Effects: Mutates fixture state and bounded region-owned byte buffers.
  entry void main() {
    long left = 0;
    while (left < 16) limit 16 {
      long right = 0;
      while (right < 16) limit 16 {
        long difference = highCoefficient(left, right);
        long average = lowCoefficient(right, difference);
        long restoredRight = average - difference;
        long restoredLeft = difference + restoredRight;
        assert(restoredLeft == left);
        assert(restoredRight == right);
        generatedCases += 1;
        right += 1;
      }

      left += 1;
    }

    long extremeDifference = highCoefficient(-1000000, 1000000);
    long extremeAverage = lowCoefficient(1000000, extremeDifference);
    assert(extremeDifference == -2000000);
    assert(extremeAverage == -1000000);
    assert(extremeAverage - extremeDifference == 1000000);
    region arena = new region(16, 2);
    bytes initial = allocateBytes(arena, 4);
    bytes restored = allocateBytes(arena, 4);
    setByte(initial, 0, high);
    setByte(initial, 1, low);
    setByte(initial, 2, highSecond);
    setByte(initial, 3, lowSecond);
    transformTile();
    observedHigh = high;
    observedLow = low;
    observedHighSecond = highSecond;
    observedLowSecond = lowSecond;
    assert(observedHigh == 4);
    assert(observedLow == 10);
    assert(observedHighSecond == 8);
    assert(observedLowSecond == 21);

    reverse {
      transformTile();
    }

    setByte(restored, 0, high);
    setByte(restored, 1, low);
    setByte(restored, 2, highSecond);
    setByte(restored, 3, lowSecond);
    assert(initial[0] == restored[0]);
    assert(initial[1] == restored[1]);
    assert(initial[2] == restored[2]);
    assert(initial[3] == restored[3]);
    assert(high == FIRST_HIGH);
    assert(low == FIRST_LOW);
    assert(highSecond == SECOND_HIGH);
    assert(lowSecond == SECOND_LOW);
    assert(generatedCases == 256);
    drop(restored);
    drop(initial);
    drop(arena);
  }
}
