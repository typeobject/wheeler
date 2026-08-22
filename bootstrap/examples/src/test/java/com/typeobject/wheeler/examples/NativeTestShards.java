package com.typeobject.wheeler.examples;

/** Supplies small independent shard-fixture calculations. */
final class NativeTestShards {
  private NativeTestShards() {}

  static int firstUnused(int shardCount, int... used) {
    for (int candidate = 0; candidate < shardCount; candidate++) {
      boolean available = true;
      for (int value : used) {
        available &= candidate != value;
      }
      if (available) {
        return candidate;
      }
    }
    throw new AssertionError("no unused shard");
  }
}
