//! Combines fixed-width bit arithmetic with one bounded immutable lookup oracle.
classical class WidthExplicitOracle {
  state long rotated = 0;
  state long masked = 0;
  state long selected = 0;

  /// Executes one 32-bit rotation and one exact four-row table lookup.
  ///
  /// - Effects: Mutates only fixture state.
  entry void main() {
    long[4] table = new long[4](3, 5, 13, 21);
    rotated = rotateRight32(1, 4);
    masked = rotated & 255;
    selected = table[2];
    assert(rotated == 268435456);
    assert(masked == 0);
    assert(selected == 13);
  }
}
