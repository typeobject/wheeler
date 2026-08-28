//! Validates bounded canonical semantic-version core triplets.

module wheeler.compiler.packages.semver_core_validation;

classical class SemverCoreValidation {
  /// Checks one decimal digit.
  public boolean semverDigit(long scalar) {
    if (scalar < 48) {
      return false;
    }

    return scalar < 58;
  }

  /// Checks one uppercase ASCII letter.
  public boolean semverUpper(long scalar) {
    if (scalar < 65) {
      return false;
    }

    return scalar < 91;
  }

  /// Checks one lowercase ASCII letter.
  public boolean semverLower(long scalar) {
    if (scalar < 97) {
      return false;
    }

    return scalar < 123;
  }

  /// Checks one semantic-version identifier scalar.
  public boolean semverIdentifierScalar(long scalar) {
    boolean numeric = semverDigit(scalar);
    if (numeric == true) {
      return true;
    }

    boolean uppercase = semverUpper(scalar);
    if (uppercase == true) {
      return true;
    }

    boolean lowercase = semverLower(scalar);
    if (lowercase == true) {
      return true;
    }

    return scalar == 45;
  }

  private long coreFinalDigitMode(long valueDigit) {
    long invalid = 0;
    long valid = 1;
    if (valueDigit < 8) {
      return valid;
    }

    return invalid;
  }

  private long coreOverflowMode(long value, long valueDigit) {
    long invalid = 0;
    long valid = 1;
    long maximumPrefix = 922337203685477580;
    long finalDigitMode = coreFinalDigitMode(valueDigit);
    if (value < maximumPrefix) {
      return valid;
    }

    if (value == maximumPrefix) {
      return finalDigitMode;
    }

    return invalid;
  }

  private long coreLeadingZeroMode(long digits, long first) {
    long invalid = 0;
    long valid = 1;
    if (digits == 0) {
      return valid;
    }

    if (first == 48) {
      return invalid;
    }

    return valid;
  }

  private long coreNumericMode(long digits, long first, long value, long valueDigit) {
    long invalid = 0;
    long leadingZeroMode = coreLeadingZeroMode(digits, first);
    long overflowMode = coreOverflowMode(value, valueDigit);
    if (leadingZeroMode == invalid) {
      return invalid;
    }

    return overflowMode;
  }

  private long coreDotMode(long dots, long digits) {
    long invalid = 0;
    long valid = 1;
    if (digits == 0) {
      return invalid;
    }

    if (dots < 2) {
      return valid;
    }

    return invalid;
  }

  private long coreMode(
    long scalar,
    long mode,
    long dots,
    long digits,
    long first,
    long value
  ) {
    long invalid = 0;
    boolean numeric = semverDigit(scalar);
    long valueDigit = scalar - 48;
    long numericMode = coreNumericMode(digits, first, value, valueDigit);
    long dotMode = coreDotMode(dots, digits);
    if (mode == invalid) {
      return invalid;
    }

    if (numeric == true) {
      return numericMode;
    }

    if (scalar == 46) {
      return dotMode;
    }

    return invalid;
  }

  private long coreDots(long scalar, long dots) {
    long next = dots + 1;
    if (scalar == 46) {
      return next;
    }

    return dots;
  }

  private long coreDigits(long scalar, long digits) {
    long zero = 0;
    long next = digits + 1;
    boolean numeric = semverDigit(scalar);
    if (numeric == true) {
      return next;
    }

    if (scalar == 46) {
      return zero;
    }

    return digits;
  }

  private long coreFirst(long scalar, long digits, long first) {
    long zero = 0;
    if (scalar == 46) {
      return zero;
    }

    if (digits == 0) {
      return scalar;
    }

    return first;
  }

  private long coreValue(long scalar, long value) {
    long zero = 0;
    long valueDigit = scalar - 48;
    long product = value * 10;
    long next = product + valueDigit;
    boolean numeric = semverDigit(scalar);
    if (numeric == true) {
      return next;
    }

    if (scalar == 46) {
      return zero;
    }

    return value;
  }

  private boolean coreComplete(long mode, long dots, long digits) {
    long valid = 1;
    long requiredDots = 2;
    if (mode < valid) {
      return false;
    }

    if (valid < mode) {
      return false;
    }

    if (dots < 2) {
      return false;
    }

    if (requiredDots < dots) {
      return false;
    }

    if (digits == 0) {
      return false;
    }

    return true;
  }

  /// Checks one canonical major, minor, and patch triplet.
  public boolean semverValidCore(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long mode = 1;
    long dots = 0;
    long digits = 0;
    long first = 0;
    long value = 0;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextMode = coreMode(scalar, mode, dots, digits, first, value);
      long nextDots = coreDots(scalar, dots);
      long nextDigits = coreDigits(scalar, digits);
      long nextFirst = coreFirst(scalar, digits, first);
      long nextValue = coreValue(scalar, value);
      mode = nextMode;
      dots = nextDots;
      digits = nextDigits;
      first = nextFirst;
      value = nextValue;
      cursor += width;
    }

    boolean complete = coreComplete(mode, dots, digits);
    return complete;
  }

}
