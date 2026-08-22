//! Reduces bounded test outcomes in case-identity order without host collections.

module wheeler.runtime.testing.test_summary;

import wheeler.core.encoding.binary;

classical class TestSummary {
  private const long CASE_BYTES = 33;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CASES = 65535;
  private const long RADIX = 256;
  private const long ROW_BYTES = 2162655;
  private const long STAGING_BYTES = 4327358;
  private const long SUMMARY_BYTES = 7;

  private void clearCounts(borrow mut words counts) {
    long digit = 0;
    while (digit < RADIX) limit RADIX {
      set(counts, digit, 0);
      digit += 1;
    }
  }

  private void countLeftDigits(
    long caseCount,
    long identityOffset,
    borrow mut bytes left,
    borrow mut words counts
  ) {
    long row = 0;
    while (row < caseCount) limit MAX_CASES {
      long digit = left[row * CASE_BYTES + identityOffset];
      set(counts, digit, counts[digit] + 1);
      row += 1;
    }
  }

  private void countRightDigits(
    long caseCount,
    long identityOffset,
    borrow mut bytes right,
    borrow mut words counts
  ) {
    long row = 0;
    while (row < caseCount) limit MAX_CASES {
      long digit = right[row * CASE_BYTES + identityOffset];
      set(counts, digit, counts[digit] + 1);
      row += 1;
    }
  }

  private void prefixCounts(borrow mut words counts, long caseCount) {
    long next = 0;
    long digit = 0;
    while (digit < RADIX) limit RADIX {
      long count = counts[digit];
      set(counts, digit, next);
      next += count;
      digit += 1;
    }

    assert(next == caseCount);
  }

  private void scatterLeft(
    long caseCount,
    long identityOffset,
    borrow mut bytes left,
    borrow mut bytes right,
    borrow mut words counts
  ) {
    long row = 0;
    while (row < caseCount) limit MAX_CASES {
      long source = row * CASE_BYTES;
      long digit = left[source + identityOffset];
      long targetRow = counts[digit];
      long target = targetRow * CASE_BYTES;
      long offset = 0;
      while (offset < CASE_BYTES) limit CASE_BYTES {
        setByte(right, target + offset, left[source + offset]);
        offset += 1;
      }

      set(counts, digit, targetRow + 1);
      row += 1;
    }
  }

  private void scatterRight(
    long caseCount,
    long identityOffset,
    borrow mut bytes right,
    borrow mut bytes left,
    borrow mut words counts
  ) {
    long row = 0;
    while (row < caseCount) limit MAX_CASES {
      long source = row * CASE_BYTES;
      long digit = right[source + identityOffset];
      long targetRow = counts[digit];
      long target = targetRow * CASE_BYTES;
      long offset = 0;
      while (offset < CASE_BYTES) limit CASE_BYTES {
        setByte(left, target + offset, right[source + offset]);
        offset += 1;
      }

      set(counts, digit, targetRow + 1);
      row += 1;
    }
  }

  private boolean sameIdentity(borrow mut bytes rows, long leftRow, long rightRow) {
    long offset = 0;
    while (offset < IDENTITY_BYTES) limit IDENTITY_BYTES {
      if (rows[leftRow * CASE_BYTES + offset] != rows[rightRow * CASE_BYTES + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private void writeUnsignedTwo(long value, borrow mut bytes output, long offset) {
    setByte(output, offset, value % 256);
    setByte(output, offset + 1, value / 256);
  }

  /// Writes selected, passed, failed, and successful fields after canonical reduction.
  public long reduceTestSummary(borrow byteview input, borrow mut bytes output) {
    assert(1 < bufferLength(input));
    assert(bufferLength(output) == SUMMARY_BYTES);
    long caseCount = readUnsigned(input, /* offset= */ 0, /* width= */ 2);
    assert(caseCount < MAX_CASES + 1);
    assert(bufferLength(input) == 2 + caseCount * CASE_BYTES);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 3);
    bytes left = allocateBytes(staging, ROW_BYTES);
    bytes right = allocateBytes(staging, ROW_BYTES);
    words counts = allocate(staging, RADIX);
    long row = 0;
    while (row < caseCount) limit MAX_CASES {
      long offset = 0;
      while (offset < CASE_BYTES) limit CASE_BYTES {
        setByte(left, row * CASE_BYTES + offset, input[2 + row * CASE_BYTES + offset]);
        offset += 1;
      }

      row += 1;
    }

    long pass = 0;
    while (pass < IDENTITY_BYTES) limit IDENTITY_BYTES {
      long identityOffset = IDENTITY_BYTES - pass - 1;
      clearCounts(counts);
      if (pass % 2 == 0) {
        countLeftDigits(caseCount, identityOffset, left, counts);
        prefixCounts(counts, caseCount);
        scatterLeft(caseCount, identityOffset, left, right, counts);
      } else {
        countRightDigits(caseCount, identityOffset, right, counts);
        prefixCounts(counts, caseCount);
        scatterRight(caseCount, identityOffset, right, left, counts);
      }

      pass += 1;
    }

    long passed = 0;
    row = 0;
    while (row < caseCount) limit MAX_CASES {
      long status = left[row * CASE_BYTES + IDENTITY_BYTES];
      assert(status < 2);
      if (status == 0) {
        passed += 1;
      }

      if (0 < row) {
        assert(sameIdentity(left, row - 1, row) == false);
      }

      row += 1;
    }

    long failed = caseCount - passed;
    writeUnsignedTwo(caseCount, output, /* offset= */ 0);
    writeUnsignedTwo(passed, output, /* offset= */ 2);
    writeUnsignedTwo(failed, output, /* offset= */ 4);
    if (failed == 0) {
      setByte(output, 6, 1);
    } else {
      setByte(output, 6, 0);
    }

    drop(counts);
    drop(right);
    drop(left);
    drop(staging);
    return SUMMARY_BYTES;
  }
}
