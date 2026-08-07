//! Owns physical and linked graph sources in one counted fixed-slot table.

module wheeler.compiler.graphs.source_table;

classical class BoundedSourceTable {
  private const long MAX_SOURCE_BYTES = 32768;
  private const long SOURCE_BYTE_LIMIT = 32769;
  /// Names the number of length words required by one source table.
  public const long SOURCE_TABLE_LENGTH_WORDS = 7;
  /// Names the complete fixed-slot source table byte capacity.
  public const long SOURCE_TABLE_BYTES = 229376;
  private const long SOURCE_TABLE_COUNT_LIMIT = 8;

  private boolean tableStorageValid(borrow mut bytes storage, borrow mut words lengths) {
    if (bufferLength(storage) == SOURCE_TABLE_BYTES) {} else {
      return false;
    }

    return bufferLength(lengths) == SOURCE_TABLE_LENGTH_WORDS;
  }

  private boolean sourceFits(borrow utf8 source) {
    long length = bufferLength(source);
    if (length < SOURCE_BYTE_LIMIT) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      if (utf8Width(source, cursor) == 1) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private void writeSourceSlot(
    long index,
    borrow utf8 source,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    long length = bufferLength(source);
    long oldLength = lengths[index];
    long slotStart = index * MAX_SOURCE_BYTES;
    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      setByte(storage, slotStart + cursor, utf8Scalar(source, cursor));
      cursor += 1;
    }

    while (cursor < oldLength) limit MAX_SOURCE_BYTES {
      setByte(storage, slotStart + cursor, 0);
      cursor += 1;
    }

    set(lengths, index, length);
  }

  /// Copies validated physical sources into one counted fixed-slot table.
  public boolean initializeSourceTable(
    long sourceCount,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    if (0 < sourceCount) {} else {
      return false;
    }

    if (sourceCount < SOURCE_TABLE_COUNT_LIMIT) {} else {
      return false;
    }

    if (tableStorageValid(storage, lengths)) {} else {
      return false;
    }

    boolean valid = sourceFits(firstSource);
    if (1 < sourceCount) {
      if (sourceFits(secondSource)) {} else {
        valid = false;
      }
    }

    if (2 < sourceCount) {
      if (sourceFits(thirdSource)) {} else {
        valid = false;
      }
    }

    if (3 < sourceCount) {
      if (sourceFits(fourthSource)) {} else {
        valid = false;
      }
    }

    if (4 < sourceCount) {
      if (sourceFits(fifthSource)) {} else {
        valid = false;
      }
    }

    if (5 < sourceCount) {
      if (sourceFits(sixthSource)) {} else {
        valid = false;
      }
    }

    if (6 < sourceCount) {
      if (sourceFits(seventhSource)) {} else {
        valid = false;
      }
    }

    if (valid) {} else {
      return false;
    }

    writeSourceSlot(0, firstSource, storage, lengths);
    if (1 < sourceCount) {
      writeSourceSlot(1, secondSource, storage, lengths);
    }

    if (2 < sourceCount) {
      writeSourceSlot(2, thirdSource, storage, lengths);
    }

    if (3 < sourceCount) {
      writeSourceSlot(3, fourthSource, storage, lengths);
    }

    if (4 < sourceCount) {
      writeSourceSlot(4, fifthSource, storage, lengths);
    }

    if (5 < sourceCount) {
      writeSourceSlot(5, sixthSource, storage, lengths);
    }

    if (6 < sourceCount) {
      writeSourceSlot(6, seventhSource, storage, lengths);
    }

    return true;
  }

  /// Replaces one active slot only after validating the complete new source.
  public boolean replaceSourceTableSlot(
    long index,
    long sourceCount,
    borrow utf8 replacement,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    if (0 < sourceCount) {} else {
      return false;
    }

    if (sourceCount < SOURCE_TABLE_COUNT_LIMIT) {} else {
      return false;
    }

    if (0 < index + 1) {} else {
      return false;
    }

    if (index < sourceCount) {} else {
      return false;
    }

    if (tableStorageValid(storage, lengths)) {} else {
      return false;
    }

    boolean validReplacement = sourceFits(replacement);
    if (validReplacement) {} else {
      return false;
    }

    writeSourceSlot(index, replacement, storage, lengths);
    return true;
  }

  /// Returns one active source slot length after checking the table index.
  public long sourceTableSlotLength(long index, long sourceCount, borrow mut words lengths) {
    assert(bufferLength(lengths) == SOURCE_TABLE_LENGTH_WORDS);
    assert(0 < sourceCount);
    assert(sourceCount < SOURCE_TABLE_COUNT_LIMIT);
    assert(0 < index + 1);
    assert(index < sourceCount);
    long length = lengths[index];
    assert(length < SOURCE_BYTE_LIMIT);
    return length;
  }

  /// Copies one active source slot into caller-owned exact-length storage.
  public long copySourceTableSlot(
    long index,
    long sourceCount,
    borrow mut bytes storage,
    borrow mut words lengths,
    borrow mut bytes output
  ) {
    long length = sourceTableSlotLength(index, sourceCount, lengths);
    assert(bufferLength(storage) == SOURCE_TABLE_BYTES);
    assert(bufferLength(output) == length);
    long slotStart = index * MAX_SOURCE_BYTES;
    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      setByte(output, cursor, storage[slotStart + cursor]);
      cursor += 1;
    }

    return length;
  }
}
