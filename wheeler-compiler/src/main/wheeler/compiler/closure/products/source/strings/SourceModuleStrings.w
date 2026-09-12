//! Orders source module names and binds duplicate spellings to one canonical string ID.

module wheeler.compiler.closure.source_module_strings;

import wheeler.compiler.closure.source_string_ranges;

classical class SourceModuleStrings {
  /// Bounds the source-local artifact string directory.
  public const long MAX_SOURCE_MODULE_STRINGS = 256;
  private const long SORTED_START_ROW = MAX_SOURCE_MODULE_STRINGS;
  private const long SORTED_LENGTH_ROW = SORTED_START_ROW + MAX_SOURCE_MODULE_STRINGS;
  private const long SORTED_INDEX_ROW = SORTED_LENGTH_ROW + MAX_SOURCE_MODULE_STRINGS;
  /// Sizes final IDs, two sorted range columns, and the stable source-row permutation.
  public const long SOURCE_MODULE_STRING_ROWS = SORTED_INDEX_ROW + MAX_SOURCE_MODULE_STRINGS;
  private const long MERGE_FANOUT = 2;

  private void mergeOrder(
    borrow byteview strings,
    long count,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words scratch
  ) {
    long initial = 0;
    while (initial < count) limit MAX_SOURCE_MODULE_STRINGS {
      set(scratch, SORTED_INDEX_ROW + initial, initial);
      initial += 1;
    }

    long width = 1;
    while (width < count) limit MAX_SOURCE_MODULE_STRINGS {
      long group = 0;
      while (group < count) limit MAX_SOURCE_MODULE_STRINGS {
        long middle = group + width;
        if (count < middle) {
          middle = count;
        }

        long end = group + width * MERGE_FANOUT;
        if (count < end) {
          end = count;
        }

        long left = group;
        long right = middle;
        long target = group;
        while (target < end) limit MAX_SOURCE_MODULE_STRINGS {
          boolean takeLeft = left < middle;
          if (takeLeft) {
            if (right < end) {
              long leftRow = scratch[SORTED_INDEX_ROW + left];
              long rightRow = scratch[SORTED_INDEX_ROW + right];
              takeLeft = compareSourceStringRanges(
                strings,
                starts[leftRow],
                lengths[leftRow],
                strings,
                starts[rightRow],
                lengths[rightRow]
              ) < 1;
            }
          }

          if (takeLeft) {
            set(scratch, target, scratch[SORTED_INDEX_ROW + left]);
            left += 1;
          } else {
            set(scratch, target, scratch[SORTED_INDEX_ROW + right]);
            right += 1;
          }

          target += 1;
        }

        group = end;
      }

      long copied = 0;
      while (copied < count) limit MAX_SOURCE_MODULE_STRINGS {
        set(scratch, SORTED_INDEX_ROW + copied, scratch[copied]);
        copied += 1;
      }

      width = width * MERGE_FANOUT;
    }
  }

  /// Sorts complete source name ranges and returns the number of unique strings.
  /// The first scratch column maps every original row to its final string ID.
  /// The other columns retain all sorted raw ranges and their stable original indices.
  /// Effects: uses private scratch, then changes only the active canonical directory prefix.
  /// Invalid input leaves both caller directory columns unchanged. No storage is allocated.
  public long materializeSourceModuleStringOrder(
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words scratch
  ) {
    assert(-1 < stringBytes);
    assert(stringBytes < MAX_SOURCE_STRING_BYTES + 1);
    assert(stringBytes < bufferLength(strings) + 1);
    assert(0 < stringCount);
    assert(stringCount < MAX_SOURCE_MODULE_STRINGS + 1);
    assert(bufferLength(starts) == MAX_SOURCE_MODULE_STRINGS);
    assert(bufferLength(lengths) == MAX_SOURCE_MODULE_STRINGS);
    assert(SOURCE_MODULE_STRING_ROWS < bufferLength(scratch) + 1);
    long checked = 0;
    while (checked < stringCount) limit MAX_SOURCE_MODULE_STRINGS {
      assert(-1 < starts[checked]);
      assert(starts[checked] < stringBytes + 1);
      assert(0 < lengths[checked]);
      assert(lengths[checked] < stringBytes - starts[checked] + 1);
      checked += 1;
    }

    mergeOrder(strings, stringCount, starts, lengths, scratch);
    long staged = 0;
    while (staged < stringCount) limit MAX_SOURCE_MODULE_STRINGS {
      long original = scratch[SORTED_INDEX_ROW + staged];
      set(scratch, SORTED_START_ROW + staged, starts[original]);
      set(scratch, SORTED_LENGTH_ROW + staged, lengths[original]);
      staged += 1;
    }

    long unique = 0;
    long previousStart = 0;
    long previousLength = 0;
    long published = 0;
    while (published < stringCount) limit MAX_SOURCE_MODULE_STRINGS {
      long start = scratch[SORTED_START_ROW + published];
      long length = scratch[SORTED_LENGTH_ROW + published];
      boolean distinct = published == 0;
      if (0 < published) {
        distinct = compareSourceStringRanges(
          strings,
          previousStart,
          previousLength,
          strings,
          start,
          length
        ) != 0;
      }

      if (distinct) {
        set(starts, unique, start);
        set(lengths, unique, length);
        unique += 1;
      }

      set(scratch, scratch[SORTED_INDEX_ROW + published], unique - 1);
      previousStart = start;
      previousLength = length;
      published += 1;
    }

    return unique;
  }
}
