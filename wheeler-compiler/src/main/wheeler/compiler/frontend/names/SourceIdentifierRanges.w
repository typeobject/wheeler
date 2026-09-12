//! Validates copied identifier bytes and compares them with independent source ranges.

module wheeler.compiler.source_identifier_ranges;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.identifier_starts;

classical class SourceIdentifierRanges {
  private const long ASCII_LIMIT = 128;
  private const long ASCII_ZERO = 48;
  private const long DECIMAL_DIGITS = 10;

  /// Checks the complete bounded ASCII spelling without mutating either view.
  public boolean copiedSourceIdentifierValid(borrow byteview names, long start, long length) {
    if (start < 0) {
      return false;
    }

    if (length < 1) {
      return false;
    }

    if (MAX_QUALIFIED_NAME_BYTES < length) {
      return false;
    }

    if (bufferLength(names) - length < start) {
      return false;
    }

    long offset = 0;
    while (offset < length) limit MAX_QUALIFIED_NAME_BYTES {
      long scalar = names[start + offset];
      boolean valid = identifierStart(scalar);
      if (0 < offset) {
        if (ASCII_ZERO - 1 < scalar) {
          if (scalar < ASCII_ZERO + DECIMAL_DIGITS) {
            valid = true;
          }
        }
      }

      if (valid == false) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Matches an ASCII source token against an independently owned name window.
  public boolean matchesSourceIdentifier(
    borrow utf8 source,
    long start,
    long length,
    borrow byteview names,
    long nameStart,
    long nameLength
  ) {
    if (start < 0) {
      return false;
    }

    if (length < 1) {
      return false;
    }

    if (MAX_QUALIFIED_NAME_BYTES < length) {
      return false;
    }

    if (bufferLength(source) - length < start) {
      return false;
    }

    if (nameStart < 0) {
      return false;
    }

    if (nameLength != length) {
      return false;
    }

    if (bufferLength(names) - length < nameStart) {
      return false;
    }

    long offset = 0;
    while (offset < length) limit MAX_QUALIFIED_NAME_BYTES {
      long value = names[nameStart + offset];
      if (ASCII_LIMIT < value + 1) {
        return false;
      }

      if (utf8Scalar(source, start + offset) != value) {
        return false;
      }

      offset += 1;
    }

    return true;
  }
}
