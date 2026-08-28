//! Compares canonical semantic versions and exposes their validation facade.

module wheeler.compiler.packages.semver;

import wheeler.compiler.packages.semver_core_validation;
import wheeler.compiler.packages.semver_prerelease_validation;

classical class Semver {
  /// Checks whether `release` satisfies the canonical profile.
  public boolean validRelease(borrow utf8 source, long start, long length) {
    return semverValidRelease(source, start, length);
  }

  /// Checks whether `constraint` satisfies the canonical profile.
  public boolean validConstraint(borrow utf8 source, long start, long length) {
    return semverValidConstraint(source, start, length);
  }

  private long coreComponent(borrow utf8 source, long start, long length, long component) {
    long cursor = start;
    long end = start + length;
    long current = 0;
    long value = 0;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      if (scalar == 45) {
        cursor = end;
      } else {
        if (scalar == 46) {
          current += 1;
        } else {
          if (current == component) {
            value = value * 10 + scalar - 48;
          }
        }

        cursor += utf8Width(source, cursor);
      }
    }

    return value;
  }

  private long prereleaseStart(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    while (cursor < end) limit 64 {
      if (utf8Scalar(source, cursor) == 45) {
        return cursor + 1;
      }

      cursor += utf8Width(source, cursor);
    }

    return end;
  }

  private long identifierEnd(borrow utf8 source, long start, long end) {
    long cursor = start;
    while (cursor < end) limit 64 {
      if (utf8Scalar(source, cursor) == 46) {
        return cursor;
      }

      cursor += utf8Width(source, cursor);
    }

    return end;
  }

  private boolean numericIdentifier(borrow utf8 source, long start, long end) {
    long cursor = start;
    while (cursor < end) limit 64 {
      if (semverDigit(utf8Scalar(source, cursor)) == false) {
        return false;
      }

      cursor += utf8Width(source, cursor);
    }

    return true;
  }

  private long compareIdentifier(
    borrow utf8 source,
    long leftStart,
    long leftEnd,
    long rightStart,
    long rightEnd
  ) {
    boolean leftNumeric = numericIdentifier(source, leftStart, leftEnd);
    boolean rightNumeric = numericIdentifier(source, rightStart, rightEnd);
    if (leftNumeric) {
      if (rightNumeric == false) {
        return -1;
      }

      long leftLength = leftEnd - leftStart;
      long rightLength = rightEnd - rightStart;
      if (leftLength < rightLength) {
        return -1;
      }

      if (rightLength < leftLength) {
        return 1;
      }
    } else {
      if (rightNumeric) {
        return 1;
      }
    }

    long left = leftStart;
    long right = rightStart;
    while (left < leftEnd) limit 64 {
      if (right < rightEnd) {
        long leftScalar = utf8Scalar(source, left);
        long rightScalar = utf8Scalar(source, right);
        if (leftScalar < rightScalar) {
          return -1;
        }

        if (rightScalar < leftScalar) {
          return 1;
        }

        left += utf8Width(source, left);
        right += utf8Width(source, right);
      } else {
        return 1;
      }
    }

    if (right < rightEnd) {
      return -1;
    }

    return 0;
  }

  /// Compares two valid canonical releases under semantic-version precedence.
  public long compareReleases(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long component = 0;
    while (component < 3) limit 3 {
      long leftValue = coreComponent(source, leftStart, leftLength, component);
      long rightValue = coreComponent(source, rightStart, rightLength, component);
      if (leftValue < rightValue) {
        return -1;
      }

      if (rightValue < leftValue) {
        return 1;
      }

      component += 1;
    }

    long leftDocumentEnd = leftStart + leftLength;
    long rightDocumentEnd = rightStart + rightLength;
    long left = prereleaseStart(source, leftStart, leftLength);
    long right = prereleaseStart(source, rightStart, rightLength);
    boolean leftStable = left == leftDocumentEnd;
    boolean rightStable = right == rightDocumentEnd;
    if (leftStable) {
      if (rightStable) {
        return 0;
      }

      return 1;
    }

    if (rightStable) {
      return -1;
    }

    while (left < leftDocumentEnd) limit 64 {
      if (right < rightDocumentEnd) {
        long leftEnd = identifierEnd(source, left, leftDocumentEnd);
        long rightEnd = identifierEnd(source, right, rightDocumentEnd);
        long comparison = compareIdentifier(source, left, leftEnd, right, rightEnd);
        if (comparison == 0) {
          left = leftEnd + 1;
          right = rightEnd + 1;
        } else {
          return comparison;
        }
      } else {
        return 1;
      }
    }

    if (right < rightDocumentEnd) {
      return -1;
    }

    return 0;
  }
}
