//! Constructs and orders native descriptors from selected source declarations.

module wheeler.runtime.testing.runners.test_discovered_descriptors;

classical class TestDiscoveredDescriptors {
  private const long MAX_CASES = 64;
  private const long MAX_NAME_BYTES = 255;
  private const long NAME_STRIDE = 255;

  private long rowSuffixLength(long row) {
    if (row < 10) {
      return 3;
    }

    assert(row < 64);
    return 4;
  }

  /// Writes one selected source case name into fixed discovery storage.
  public void writeDiscoveredCaseName(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    borrow byteview targetName,
    borrow byteview moduleInput,
    long moduleStart,
    long moduleLength,
    boolean qualifyModule,
    long row,
    long ordinal,
    borrow mut bytes names,
    borrow mut words nameLengths
  ) {
    assert(bufferLength(names) == MAX_CASES * NAME_STRIDE);
    assert(bufferLength(nameLengths) == MAX_CASES);
    assert(ordinal < MAX_CASES);
    long targetLength = bufferLength(targetName);
    long nameLength = targetLength + 2 + tokenLengths[nameToken];
    if (qualifyModule) {
      nameLength += moduleLength + 2;
    }

    if (-1 < row) {
      nameLength += rowSuffixLength(row);
    }

    assert(nameLength < MAX_NAME_BYTES + 1);
    long cursor = ordinal * NAME_STRIDE;
    long offset = 0;
    while (offset < targetLength) limit MAX_NAME_BYTES {
      setByte(names, cursor, targetName[offset]);
      cursor += 1;
      offset += 1;
    }

    setByte(names, cursor, 58);
    setByte(names, cursor + 1, 58);
    cursor += 2;
    if (qualifyModule) {
      offset = 0;
      while (offset < moduleLength) limit MAX_NAME_BYTES {
        setByte(names, cursor, moduleInput[moduleStart + offset]);
        cursor += 1;
        offset += 1;
      }

      setByte(names, cursor, 58);
      setByte(names, cursor + 1, 58);
      cursor += 2;
    }

    offset = 0;
    while (offset < tokenLengths[nameToken]) limit MAX_NAME_BYTES {
      setByte(names, cursor, utf8Scalar(source, tokenStarts[nameToken] + offset));
      cursor += 1;
      offset += 1;
    }

    if (-1 < row) {
      setByte(names, cursor, 91);
      cursor += 1;
      if (row < 10) {
        setByte(names, cursor, 48 + row);
        cursor += 1;
      } else {
        setByte(names, cursor, 48 + row / 10);
        setByte(names, cursor + 1, 48 + row % 10);
        cursor += 2;
      }

      setByte(names, cursor, 93);
      cursor += 1;
    }

    assert(cursor == ordinal * NAME_STRIDE + nameLength);
    set(nameLengths, ordinal, nameLength);
  }

  private long compareNames(
    borrow byteview names,
    borrow mut words nameLengths,
    long left,
    long right
  ) {
    long leftLength = nameLengths[left];
    long rightLength = nameLengths[right];
    long length = leftLength;
    if (rightLength < length) {
      length = rightLength;
    }

    long leftStart = left * NAME_STRIDE;
    long rightStart = right * NAME_STRIDE;
    long offset = 0;
    while (offset < length) limit MAX_NAME_BYTES {
      if (names[leftStart + offset] < names[rightStart + offset]) {
        return -1;
      }

      if (names[rightStart + offset] < names[leftStart + offset]) {
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

  private void swapWord(borrow mut words values, long left, long right) {
    long value = values[left];
    set(values, left, values[right]);
    set(values, right, value);
  }

  private void swapNames(borrow mut bytes names, long left, long right) {
    long leftStart = left * NAME_STRIDE;
    long rightStart = right * NAME_STRIDE;
    long offset = 0;
    while (offset < NAME_STRIDE) limit NAME_STRIDE {
      long value = names[leftStart + offset];
      setByte(names, leftStart + offset, names[rightStart + offset]);
      setByte(names, rightStart + offset, value);
      offset += 1;
    }
  }

  /// Sorts names and their discovery metadata into canonical descriptor order.
  public void sortDiscoveredCases(
    borrow mut bytes names,
    borrow mut words nameLengths,
    borrow mut words caseKinds,
    borrow mut words caseValues,
    borrow mut words caseStepLimits,
    long count
  ) {
    assert(bufferLength(names) == MAX_CASES * NAME_STRIDE);
    assert(bufferLength(nameLengths) == MAX_CASES);
    assert(bufferLength(caseKinds) == MAX_CASES);
    assert(bufferLength(caseValues) == MAX_CASES);
    assert(bufferLength(caseStepLimits) == MAX_CASES);
    assert(count < MAX_CASES + 1);
    long pass = 0;
    while (pass < count) limit MAX_CASES {
      long item = 1;
      while (item < count - pass) limit MAX_CASES {
        if (0 < compareNames(names, nameLengths, item - 1, item)) {
          swapNames(names, item - 1, item);
          swapWord(nameLengths, item - 1, item);
          swapWord(caseKinds, item - 1, item);
          swapWord(caseValues, item - 1, item);
          swapWord(caseStepLimits, item - 1, item);
        }

        item += 1;
      }

      pass += 1;
    }

    long verifiedItem = 1;
    while (verifiedItem < count) limit MAX_CASES {
      assert(compareNames(names, nameLengths, verifiedItem - 1, verifiedItem) == -1);
      verifiedItem += 1;
    }
  }
}
