//! Selects helper source frames by canonical root-import range.

module wheeler.compiler.helper_source_order;

classical class HelperSourceOrder {
  private const long MAX_HELPER_SOURCES = 7;

  /// Selects the source with one canonical rank from active module-range starts.
  public long helperSourceAtRank(long rank, long[7] starts, long count) {
    if (0 < count) {} else {
      assert(0 == 1);
    }

    if (count < MAX_HELPER_SOURCES + 1) {} else {
      assert(0 == 1);
    }

    if (-1 < rank) {} else {
      assert(0 == 1);
    }

    if (rank < count) {} else {
      assert(0 == 1);
    }

    long source = 0;
    while (source < count) limit MAX_HELPER_SOURCES {
      long sourceRank = 0;
      long other = 0;
      while (other < count) limit MAX_HELPER_SOURCES {
        if (starts[other] < starts[source]) {
          sourceRank += 1;
        }

        other += 1;
      }

      if (sourceRank == rank) {
        return source;
      }

      source += 1;
    }

    assert(0 == 1);
    return 0;
  }
}
