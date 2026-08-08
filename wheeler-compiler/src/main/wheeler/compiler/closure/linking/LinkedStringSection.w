//! Emits one canonical sorted string section from counted bootstrap name ranges.

module wheeler.compiler.closure.linked_string_section;

classical class LinkedStringSection {
  private const long MAX_STRING_BYTES = 1048576;
  private const long MAX_STRINGS = 16384;

  private long compareStrings(
    borrow byteview archive,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long index = 0;
    while (index < shared) limit 4096 {
      long left = archive[leftStart + index];
      long right = archive[rightStart + index];
      if (left < right) {
        return -1;
      }

      if (right < left) {
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

  /// Emits canonical ASCII bootstrap names and publishes each source-to-final ID.
  public long emitLinkedStringSection(
    borrow byteview archive,
    long archiveBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words finalStringRows,
    borrow mut bytes output
  ) {
    assert(-1 < archiveBytes);
    assert(archiveBytes < bufferLength(archive) + 1);
    assert(0 < stringCount);
    assert(stringCount < MAX_STRINGS + 1);
    assert(bufferLength(stringStarts) == MAX_STRINGS);
    assert(bufferLength(stringLengths) == MAX_STRINGS);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(bufferLength(output) == MAX_STRING_BYTES);

    long string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long start = stringStarts[string];
      long stringLength = stringLengths[string];
      assert(-1 < start);
      assert(0 < stringLength);
      assert(start < archiveBytes + 1);
      assert(stringLength < archiveBytes - start + 1);
      long stringByte = 0;
      while (stringByte < stringLength) limit 4096 {
        long value = archive[start + stringByte];
        assert(0 < value);
        assert(value < 128);
        stringByte += 1;
      }

      string += 1;
    }

    region staging = new region(/* bytes= */ 262144, /* allocations= */ 2);
    words sortedStrings = allocate(staging, MAX_STRINGS);
    words stagedRows = allocate(staging, MAX_STRINGS);
    long uniqueCount = 0;
    string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long low = 0;
      long high = uniqueCount;
      boolean equal = false;
      long equalId = -1;
      while (low < high) limit MAX_STRINGS {
        long middle = low + (high - low) / 2;
        long selected = sortedStrings[middle];
        long comparison = compareStrings(
          archive,
          stringStarts[string],
          stringLengths[string],
          stringStarts[selected],
          stringLengths[selected]
        );
        if (comparison == 0) {
          equal = true;
          equalId = middle;
          low = high;
        } else {
          if (comparison < 0) {
            high = middle;
          } else {
            low = middle + 1;
          }
        }
      }

      if (equal) {
        set(stagedRows, string, equalId);
      } else {
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

    string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long mapLow = 0;
      long mapHigh = uniqueCount;
      long selectedId = -1;
      while (mapLow < mapHigh) limit MAX_STRINGS {
        long mapMiddle = mapLow + (mapHigh - mapLow) / 2;
        long mapSelected = sortedStrings[mapMiddle];
        long mapComparison = compareStrings(
          archive,
          stringStarts[string],
          stringLengths[string],
          stringStarts[mapSelected],
          stringLengths[mapSelected]
        );
        if (mapComparison == 0) {
          selectedId = mapMiddle;
          mapLow = mapHigh;
        } else {
          if (mapComparison < 0) {
            mapHigh = mapMiddle;
          } else {
            mapLow = mapMiddle + 1;
          }
        }
      }

      assert(-1 < selectedId);
      set(stagedRows, string, selectedId);
      string += 1;
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

    writeUnsigned(uniqueCount, output, 0);
    long cursor = 4;
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
      set(finalStringRows, string, stagedRows[string]);
      string += 1;
    }

    assert(cursor == sectionBytes);
    drop(stagedRows);
    drop(sortedStrings);
    drop(staging);
    return sectionBytes;
  }
}
