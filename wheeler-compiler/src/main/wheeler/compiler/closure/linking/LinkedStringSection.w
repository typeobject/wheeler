//! Emits one canonical sorted string section from counted bootstrap name ranges.

module wheeler.compiler.closure.linked_string_section;

classical class LinkedStringSection {
  private const long MAX_STRING_BYTES = 1048576;
  private const long MAX_STRINGS = 16384;

  private long compareStrings(
    borrow byteview archive,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words heads,
    borrow mut words tails,
    long left,
    long right
  ) {
    if (heads[left] < heads[right]) {
      return -1;
    }

    if (heads[right] < heads[left]) {
      return 1;
    }

    if (tails[left] < tails[right]) {
      return -1;
    }

    if (tails[right] < tails[left]) {
      return 1;
    }

    long leftStart = starts[left];
    long leftLength = lengths[left];
    long rightStart = starts[right];
    long rightLength = lengths[right];
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long index = 16;
    while (index < shared) limit 4096 {
      long leftByte = archive[leftStart + index];
      long rightByte = archive[rightStart + index];
      if (leftByte < rightByte) {
        return -1;
      }

      if (rightByte < leftByte) {
        return 1;
      }

      index += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  private void writeUnsigned(long value, borrow mut bytes output, long cursor) {
    long remaining = value;
    long outputByte = 0;
    while (outputByte < 4) limit 4 {
      setByte(output, cursor + outputByte, remaining % 256);
      remaining = remaining / 256;
      outputByte += 1;
    }

    assert(remaining == 0);
  }

  /// Emits canonical ASCII bootstrap names at a caller-selected section offset.
  public long emitLinkedStringSectionAt(
    borrow byteview archive,
    long archiveBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words finalStringRows,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < outputStart);
    assert(-1 < archiveBytes);
    assert(archiveBytes < bufferLength(archive) + 1);
    assert(0 < stringCount);
    assert(stringCount < MAX_STRINGS + 1);
    assert(bufferLength(stringStarts) == MAX_STRINGS);
    assert(bufferLength(stringLengths) == MAX_STRINGS);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(outputStart < bufferLength(output) + 1);

    long string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long start = stringStarts[string];
      long stringLength = stringLengths[string];
      assert(-1 < start);
      assert(0 < stringLength);
      assert(start < archiveBytes + 1);
      assert(stringLength < archiveBytes - start + 1);
      string += 1;
    }

    region staging = new region(/* bytes= */ 524288, /* allocations= */ 4);
    words sortedStrings = allocate(staging, MAX_STRINGS);
    words stagedRows = allocate(staging, MAX_STRINGS);
    words heads = allocate(staging, MAX_STRINGS);
    words tails = allocate(staging, MAX_STRINGS);
    // Nonzero ASCII bytes give two exact, zero-padded big-endian prefixes.
    // Their sign bits stay clear. Equal prefixes still require suffix comparison.
    string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long prefixStart = stringStarts[string];
      long prefixLength = stringLengths[string];
      long head = 0;
      long tail = 0;
      long headPlace = 72057594037927936;
      long tailPlace = 72057594037927936;
      long stringByte = 0;
      while (stringByte < prefixLength) limit 4096 {
        long value = archive[prefixStart + stringByte];
        assert(0 < value);
        assert(value < 128);
        if (stringByte < 8) {
          head += value * headPlace;
          headPlace = headPlace / 256;
        } else {
          if (stringByte < 16) {
            tail += value * tailPlace;
            tailPlace = tailPlace / 256;
          }
        }

        stringByte += 1;
      }

      set(heads, string, head);
      set(tails, string, tail);
      string += 1;
    }

    long uniqueCount = 0;
    string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long low = 0;
      long high = uniqueCount;
      boolean equal = false;
      while (low < high) limit MAX_STRINGS {
        long middle = low + (high - low) / 2;
        long selected = sortedStrings[middle];
        long comparison = compareStrings(
          archive,
          stringStarts,
          stringLengths,
          heads,
          tails,
          string,
          selected
        );
        if (comparison == 0) {
          // Keep the source row, not the sorted position that later insertions move.
          set(stagedRows, string, -1 - selected);
          equal = true;
          low = high;
        } else {
          if (comparison < 0) {
            high = middle;
          } else {
            low = middle + 1;
          }
        }
      }

      if (!equal) {
        long insertion = low;
        long shift = uniqueCount;
        while (insertion < shift) limit MAX_STRINGS {
          set(sortedStrings, shift, sortedStrings[shift - 1]);
          shift -= 1;
        }

        set(sortedStrings, insertion, string);
        uniqueCount += 1;
      }

      string += 1;
    }

    // Unique source rows receive final IDs. Negative rows still name representatives.
    long finalId = 0;
    while (finalId < uniqueCount) limit MAX_STRINGS {
      set(stagedRows, sortedStrings[finalId], finalId);
      finalId += 1;
    }

    long sectionBytes = 4;
    long unique = 0;
    while (unique < uniqueCount) limit MAX_STRINGS {
      long extentString = sortedStrings[unique];
      long extentLength = stringLengths[extentString];
      assert(extentLength < MAX_STRING_BYTES - sectionBytes - 4 + 1);
      sectionBytes += 4 + extentLength;
      unique += 1;
    }

    assert(sectionBytes < bufferLength(output) - outputStart + 1);
    writeUnsigned(uniqueCount, output, outputStart);
    long cursor = outputStart + 4;
    unique = 0;
    while (unique < uniqueCount) limit MAX_STRINGS {
      long selectedString = sortedStrings[unique];
      long selectedLength = stringLengths[selectedString];
      writeUnsigned(selectedLength, output, cursor);
      cursor += 4;
      long selectedByte = 0;
      while (selectedByte < selectedLength) limit 4096 {
        setByte(
          output,
          cursor + selectedByte,
          archive[stringStarts[selectedString] + selectedByte]
        );
        selectedByte += 1;
      }

      cursor += selectedLength;
      unique += 1;
    }

    string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long finalRow = stagedRows[string];
      if (finalRow < 0) {
        finalRow = stagedRows[-1 - finalRow];
      }

      set(finalStringRows, string, finalRow);
      string += 1;
    }

    assert(cursor == outputStart + sectionBytes);
    drop(tails);
    drop(heads);
    drop(stagedRows);
    drop(sortedStrings);
    drop(staging);
    return sectionBytes;
  }
}
