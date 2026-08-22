//! Reduces bounded canonical transition-point fragments without host collections.

module wheeler.runtime.coverage_reducer;

classical class CoverageReducer {
  const long MAX_ROWS = 128;
  const long MAX_ROW_BYTES = 256;

  long readUnsigned16(borrow byteview input, long offset) {
    return input[offset] + input[offset + 1] * 256;
  }

  long compareRows(
    borrow byteview input,
    long left,
    long right,
    borrow mut words keyStarts,
    borrow mut words keyLengths
  ) {
    long leftLength = keyLengths[left];
    long rightLength = keyLengths[right];
    long common = leftLength;
    if (rightLength < common) {
      common = rightLength;
    }

    long offset = 0;
    while (offset < common) limit MAX_ROW_BYTES {
      long leftByte = input[keyStarts[left] + offset];
      long rightByte = input[keyStarts[right] + offset];
      if (leftByte < rightByte) {
        return -1;
      }

      if (rightByte < leftByte) {
        return 1;
      }

      offset += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  long copyInput(
    borrow byteview input,
    long inputStart,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long offset = 0;
    while (offset < length) limit MAX_ROW_BYTES {
      setByte(output, outputStart + offset, input[inputStart + offset]);
      offset += 1;
    }

    return outputStart + length;
  }

  long decimalDigits(long value) {
    long digits = 1;
    long remaining = value;
    while (9 < remaining) limit 20 {
      remaining = remaining / 10;
      digits += 1;
    }

    return digits;
  }

  long writeCount(long value, borrow mut bytes output, long cursor) {
    long digits = decimalDigits(value);
    long divisor = 1;
    long position = 1;
    while (position < digits) limit 20 {
      divisor = divisor * 10;
      position += 1;
    }

    position = 0;
    while (position < digits) limit 20 {
      setByte(output, cursor + position, value / divisor % 10 + 48);
      divisor = divisor / 10;
      position += 1;
    }

    return cursor + digits;
  }

  long writeHeader(borrow mut bytes output, long cursor) {
    setByte(output, cursor, 123);
    setByte(output, cursor + 1, 34);
    writeAscii(output, cursor + 2, "points");
    setByte(output, cursor + 8, 34);
    setByte(output, cursor + 9, 58);
    setByte(output, cursor + 10, 91);
    return cursor + 11;
  }

  long writeCountLabel(borrow mut bytes output, long cursor) {
    setByte(output, cursor, 44);
    setByte(output, cursor + 1, 34);
    writeAscii(output, cursor + 2, "count");
    setByte(output, cursor + 7, 34);
    setByte(output, cursor + 8, 58);
    return cursor + 9;
  }

  long writeFooter(borrow mut bytes output, long cursor) {
    setByte(output, cursor, 93);
    setByte(output, cursor + 1, 44);
    setByte(output, cursor + 2, 34);
    writeAscii(output, cursor + 3, "profile");
    setByte(output, cursor + 10, 34);
    setByte(output, cursor + 11, 58);
    setByte(output, cursor + 12, 34);
    writeAscii(output, cursor + 13, "wheeler-transition-coverage-1");
    setByte(output, cursor + 42, 34);
    setByte(output, cursor + 43, 125);
    setByte(output, cursor + 44, 10);
    return cursor + 45;
  }

  long readField(
    borrow byteview input,
    long cursor,
    long row,
    borrow mut words starts,
    borrow mut words lengths
  ) {
    assert(cursor + 1 < bufferLength(input));
    long length = readUnsigned16(input, cursor);
    cursor += 2;
    assert(0 < length);
    assert(length < MAX_ROW_BYTES + 1);
    assert(cursor + length < bufferLength(input) + 1);
    set(starts, row, cursor);
    set(lengths, row, length);
    return cursor + length;
  }

  /// Emits the profile-1 report from one exact input prefix.
  ///
  /// - Effects: Publishes output length only after the complete bounded report exists.
  public long reduceRange(borrow byteview input, long inputLength, borrow mut bytes output) {
    assert(0 < inputLength);
    assert(inputLength < bufferLength(input) + 1);
    long rowCount = input[0];
    assert(rowCount < MAX_ROWS + 1);
    region arena = new region(8192, 7);
    words keyStarts = allocate(arena, MAX_ROWS);
    words keyLengths = allocate(arena, MAX_ROWS);
    words prefixStarts = allocate(arena, MAX_ROWS);
    words prefixLengths = allocate(arena, MAX_ROWS);
    words suffixStarts = allocate(arena, MAX_ROWS);
    words suffixLengths = allocate(arena, MAX_ROWS);
    words order = allocate(arena, MAX_ROWS);
    long cursor = 1;
    long row = 0;
    while (row < rowCount) limit MAX_ROWS {
      cursor = readField(input, cursor, row, keyStarts, keyLengths);
      cursor = readField(input, cursor, row, prefixStarts, prefixLengths);
      cursor = readField(input, cursor, row, suffixStarts, suffixLengths);
      assert(prefixLengths[row] + suffixLengths[row] < MAX_ROW_BYTES + 1);
      set(order, row, row);
      row += 1;
    }

    assert(cursor == inputLength);
    long selected = 1;
    while (selected < rowCount) limit MAX_ROWS {
      long position = selected;
      while (0 < position) limit MAX_ROWS {
        long left = order[position - 1];
        long right = order[position];
        long comparison = compareRows(input, left, right, keyStarts, keyLengths);
        if (comparison < 1) {
          position = 0;
        } else {
          set(order, position - 1, right);
          set(order, position, left);
          position -= 1;
        }
      }

      selected += 1;
    }

    cursor = writeHeader(output, 0);
    long ordered = 0;
    long published = 0;
    while (ordered < rowCount) limit MAX_ROWS {
      long selectedRow = order[ordered];
      long count = 1;
      long candidateOffset = 1;
      boolean scanning = true;
      while (ordered + candidateOffset < rowCount) limit MAX_ROWS {
        if (scanning) {
          long candidate = order[ordered + candidateOffset];
          long groupComparison = compareRows(
            input,
            selectedRow,
            candidate,
            keyStarts,
            keyLengths
          );
          if (groupComparison == 0) {
            count += 1;
          } else {
            scanning = false;
          }
        }

        candidateOffset += 1;
      }

      if (0 < published) {
        setByte(output, cursor, 44);
        cursor += 1;
      }

      cursor = copyInput(
        input,
        prefixStarts[selectedRow],
        prefixLengths[selectedRow],
        output,
        cursor
      );
      cursor = writeCountLabel(output, cursor);
      cursor = writeCount(count, output, cursor);
      cursor = copyInput(
        input,
        suffixStarts[selectedRow],
        suffixLengths[selectedRow],
        output,
        cursor
      );
      ordered += count;
      published += 1;
    }

    cursor = writeFooter(output, cursor);
    drop(order);
    drop(suffixLengths);
    drop(suffixStarts);
    drop(prefixLengths);
    drop(prefixStarts);
    drop(keyLengths);
    drop(keyStarts);
    drop(arena);
    return cursor;
  }

  /// Emits the profile-1 report after complete input validation and row sorting.
  ///
  /// - Effects: Publishes output length only after the complete bounded report exists.
  public long reduce(borrow byteview input, borrow mut bytes output) {
    return reduceRange(input, bufferLength(input), output);
  }
}
