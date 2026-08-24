//! Validates one canonical native test-tag selection frame.

module wheeler.runtime.testing.runners.test_tag_selection;

classical class TestTagSelection {
  private const long MAX_TAGS = 64;
  private const long MAX_TAG_BYTES = 128;

  /// Reports the first byte after one validated tag frame.
  public record TagSelection(boolean valid, long end) {}

  private boolean segmentStart(long value) {
    if (value == 95) {
      return true;
    }

    if (64 < value) {
      if (value < 91) {
        return true;
      }
    }

    if (96 < value) {
      return value < 123;
    }

    return false;
  }

  private boolean segmentPart(long value) {
    if (segmentStart(value)) {
      return true;
    }

    if (47 < value) {
      return value < 58;
    }

    return false;
  }

  private boolean validTag(borrow byteview input, long start, long length) {
    if (length < 1) {
      return false;
    }

    if (MAX_TAG_BYTES < length) {
      return false;
    }

    boolean atStart = true;
    long offset = 0;
    while (offset < length) limit MAX_TAG_BYTES {
      long value = input[start + offset];
      if (atStart) {
        if (segmentStart(value) == false) {
          return false;
        }

        atStart = false;
      } else {
        if (value == 46) {
          atStart = true;
        } else {
          if (segmentPart(value) == false) {
            return false;
          }
        }
      }

      offset += 1;
    }

    return atStart == false;
  }

  private long compareTag(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long length = leftLength;
    if (rightLength < length) {
      length = rightLength;
    }

    long offset = 0;
    while (offset < length) limit MAX_TAG_BYTES {
      if (input[leftStart + offset] < input[rightStart + offset]) {
        return -1;
      }

      if (input[rightStart + offset] < input[leftStart + offset]) {
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

  /// Validates `count` length-prefixed tags in strict lexical order.
  public TagSelection validatedTagSelection(borrow byteview input, long start, long count) {
    if (MAX_TAGS < count) {
      return new TagSelection(false, start);
    }

    long cursor = start;
    long previousStart = 0;
    long previousLength = 0;
    long tag = 0;
    while (tag < count) limit MAX_TAGS {
      if (cursor < bufferLength(input)) {} else {
        return new TagSelection(false, cursor);
      }

      long length = input[cursor];
      cursor += 1;
      if (cursor + length < bufferLength(input) + 1) {} else {
        return new TagSelection(false, cursor);
      }

      if (validTag(input, cursor, length) == false) {
        return new TagSelection(false, cursor);
      }

      if (0 < tag) {
        if (compareTag(input, previousStart, previousLength, cursor, length) != -1) {
          return new TagSelection(false, cursor);
        }
      }

      previousStart = cursor;
      previousLength = length;
      cursor += length;
      tag += 1;
    }

    return new TagSelection(true, cursor);
  }
}
