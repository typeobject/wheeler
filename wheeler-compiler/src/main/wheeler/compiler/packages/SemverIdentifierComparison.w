//! Compares bounded semantic-version prerelease identifiers.

module wheeler.compiler.packages.semver_identifier_comparison;

import wheeler.compiler.packages.semver_core_validation;

classical class SemverIdentifierComparison {
  private long numericState(long current, boolean digit) {
    if (current == 0) {
      return 0;
    }

    if (digit == true) {
      return 1;
    }

    return 0;
  }

  private boolean numericResult(long state) {
    if (state == 1) {
      return true;
    }

    return false;
  }

  /// Checks whether one nonempty identifier contains only ASCII digits.
  public boolean semverNumericIdentifier(borrow utf8 source, long start, long end) {
    long cursor = start;
    long numeric = 1;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      boolean digit = semverDigit(scalar);
      long nextNumeric = numericState(numeric, digit);
      long nextCursor = cursor + width;
      cursor = nextCursor;
      numeric = nextNumeric;
    }

    return numericResult(numeric);
  }

  private long identifierKind(boolean numeric) {
    if (numeric == true) {
      return 0;
    }

    return 1;
  }

  private long classComparison(boolean leftNumeric, boolean rightNumeric) {
    long leftKind = identifierKind(leftNumeric);
    long rightKind = identifierKind(rightNumeric);
    if (leftKind < rightKind) {
      return -1;
    }

    if (rightKind < leftKind) {
      return 1;
    }

    return 0;
  }

  private long numericLengthComparison(boolean numeric, long leftLength, long rightLength) {
    if (numeric == false) {
      return 0;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  private long commonLength(long leftLength, long rightLength) {
    if (leftLength < rightLength) {
      return leftLength;
    }

    return rightLength;
  }

  private long prefixLengthComparison(long prefixComparison, long leftLength, long rightLength) {
    if (prefixComparison < 0) {
      return prefixComparison;
    }

    if (prefixComparison == 1) {
      return prefixComparison;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  private long lexicalComparison(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long common = commonLength(leftLength, rightLength);
    long comparison = 0;
    long offset = 0;
    long reverse = common;
    while (offset < common) limit 64 {
      reverse -= 1;
      long leftIndex = leftStart + reverse;
      long rightIndex = rightStart + reverse;
      long leftScalar = utf8Scalar(source, leftIndex);
      long rightScalar = utf8Scalar(source, rightIndex);
      if (leftScalar < rightScalar) {
        comparison = -1;
      }

      if (rightScalar < leftScalar) {
        comparison = 1;
      }

      offset += 1;
    }

    return prefixLengthComparison(comparison, leftLength, rightLength);
  }

  private long firstComparison(long first, long second) {
    if (first < 0) {
      return first;
    }

    if (first == 1) {
      return first;
    }

    return second;
  }

  /// Compares two nonempty identifiers under semantic-version precedence.
  public long semverCompareIdentifier(
    borrow utf8 source,
    long leftStart,
    long leftEnd,
    long rightStart,
    long rightEnd
  ) {
    boolean leftNumeric = semverNumericIdentifier(source, leftStart, leftEnd);
    boolean rightNumeric = semverNumericIdentifier(source, rightStart, rightEnd);
    long leftLength = leftEnd - leftStart;
    long rightLength = rightEnd - rightStart;
    long classes = classComparison(leftNumeric, rightNumeric);
    long lengths = numericLengthComparison(leftNumeric, leftLength, rightLength);
    long classOrLength = firstComparison(classes, lengths);
    long lexical = lexicalComparison(source, leftStart, leftLength, rightStart, rightLength);
    return firstComparison(classOrLength, lexical);
  }
}
