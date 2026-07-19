//! Exercises canonical deterministic operations over a caller-owned bounded signed map.

module examples.collections.long_map_main;

import wheeler.core.collections.long_map;

classical class LongMap {
  state long selected = 0;
  state long present = 0;
  state long missing = 0;
  state long zeroKey = 0;

  /// Runs the bounded `LongMap` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main() {
    region arena = new region(96, 1);
    longmap values = allocateMap(arena, 4);
    put(values, 7, 11);
    put(values, 9, 13);
    selected = putAndGet(values, 7, 17);
    zeroKey = putAndGet(values, 0, 5);
    boolean hasNine = containsKey(values, 9);
    boolean hasThree = containsKey(values, 3);
    if (hasNine) {
      present = 1;
    } else {
      present = 0;
    }

    if (hasThree) {
      missing = 0;
    } else {
      missing = 1;
    }

    assert(selected == 17);
    assert(zeroKey == 5);
    assert(present == 1);
    assert(missing == 1);
    drop(values);
    drop(arena);
  }
}
