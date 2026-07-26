//! Fixed immutable arrays with core reductions, checked indexing, and value equality.

module examples.collections.fixed_arrays_main;

import wheeler.core.collections.fixed_longs;

classical class FixedArrays {
  record ArrayPair(long[2] values, boolean[2] flags) {}

  variant ArrayOption {
    case None();
    case Some(long[2] values);
  }

  state long selected = 0;
  state long sum = 0;
  state long equal = 0;
  state long middleSum = 0;
  state long recordSelected = 0;
  state long variantSelected = 0;

  long[4] sequence() {
    return new long[4](2, 4, 6, 8);
  }

  /// Runs the bounded `FixedArrays` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main() {
    long[4] first = sequence();
    long[4] second = new long[4](2, 4, 6, 8);
    long[] middle = slice(first, 1, 2);
    ArrayPair pair = new ArrayPair(new long[2](3, 7), new boolean[2](true, false));
    ArrayOption option = new ArrayOption.Some(new long[2](11, 13));
    selected = middle[1];
    sum = total4(first);
    middleSum = subtotal2(middle);
    if (first == second) {
      equal = 1;
    }

    if (pair.flags[0]) {
      recordSelected = pair.values[1];
    }

    match (option) {
      case ArrayOption.None() {
        variantSelected = 1;
      }
      case ArrayOption.Some(long[2] values) {
        variantSelected = values[1];
      }
    }

    assert(selected == 6);
    assert(sum == 20);
    assert(middleSum == 10);
    assert(equal == 1);
    assert(recordSelected == 7);
    assert(variantSelected == 13);
  }
}
