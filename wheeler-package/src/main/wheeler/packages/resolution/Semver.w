//! Validates bounded canonical releases and version constraints.

module wheeler.packages.semver;

classical class Semver {
  private boolean digit(long scalar) {
    if (47 < scalar) {
      return scalar < 58;
    }

    return false;
  }

  private boolean upper(long scalar) {
    if (64 < scalar) {
      return scalar < 91;
    }

    return false;
  }

  private boolean lower(long scalar) {
    if (96 < scalar) {
      return scalar < 123;
    }

    return false;
  }

  private boolean identifierScalar(long scalar) {
    boolean numeric = digit(scalar);
    if (numeric) {
      return true;
    }

    boolean uppercase = upper(scalar);
    if (uppercase) {
      return true;
    }

    boolean lowercase = lower(scalar);
    if (lowercase) {
      return true;
    }

    return scalar == 45;
  }

  private boolean validCore(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long dots = 0;
    long digits = 0;
    long first = 0;
    long value = 0;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      boolean numeric = digit(scalar);
      if (numeric) {
        long valueDigit = scalar - 48;
        if (digits == 0) {
          first = scalar;
        } else {
          if (first == 48) {
            return false;
          }
        }

        if (922337203685477580 < value) {
          return false;
        }

        if (value == 922337203685477580) {
          if (7 < valueDigit) {
            return false;
          }
        }

        value = value * 10 + valueDigit;
        digits += 1;
      } else {
        if (scalar == 46) {
          if (digits == 0) {
            return false;
          }

          dots += 1;
          if (2 < dots) {
            return false;
          }

          digits = 0;
          first = 0;
          value = 0;
        } else {
          return false;
        }
      }

      cursor += utf8Width(source, cursor);
    }

    if (dots == 2) {
      return 0 < digits;
    }

    return false;
  }

  private boolean validPrerelease(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long partLength = 0;
    long first = 0;
    boolean numericPart = true;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      if (scalar == 46) {
        if (partLength == 0) {
          return false;
        }

        if (numericPart) {
          if (first == 48) {
            if (1 < partLength) {
              return false;
            }
          }
        }

        partLength = 0;
        first = 0;
        numericPart = true;
      } else {
        boolean allowed = identifierScalar(scalar);
        if (allowed) {
          if (partLength == 0) {
            first = scalar;
          }

          boolean numeric = digit(scalar);
          if (numeric) {
            partLength += 1;
          } else {
            numericPart = false;
            partLength += 1;
          }
        } else {
          return false;
        }
      }

      cursor += utf8Width(source, cursor);
    }

    if (partLength == 0) {
      return false;
    }

    if (numericPart) {
      if (first == 48) {
        return partLength == 1;
      }
    }

    return true;
  }

  /// Checks whether `release` satisfies the canonical profile.
  public boolean validRelease(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long coreLength = length;
    long prereleaseStart = end;
    boolean hasPrerelease = false;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      if (scalar == 45) {
        coreLength = cursor - start;
        prereleaseStart = cursor + 1;
        hasPrerelease = true;
        cursor = end;
      } else {
        cursor += utf8Width(source, cursor);
      }
    }

    boolean core = validCore(source, start, coreLength);
    if (core) {
      if (hasPrerelease) {
        return validPrerelease(source, prereleaseStart, end - prereleaseStart);
      }

      return true;
    }

    return false;
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
      if (digit(utf8Scalar(source, cursor)) == false) {
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

  /// Checks whether `constraint` satisfies the canonical profile.
  public boolean validConstraint(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long scalar = utf8Scalar(source, start);
    if (scalar == 61) {
      return prefixedRelease(source, start, length);
    }

    if (scalar == 94) {
      return prefixedRelease(source, start, length);
    }

    if (scalar == 126) {
      return prefixedRelease(source, start, length);
    }

    return validRelease(source, start, length);
  }

  private boolean prefixedRelease(borrow utf8 source, long start, long length) {
    if (length == 1) {
      return false;
    }

    return validRelease(source, start + 1, length - 1);
  }
}
