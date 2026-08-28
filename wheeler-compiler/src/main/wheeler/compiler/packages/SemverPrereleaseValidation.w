//! Validates canonical semantic-version prereleases and constraints.

module wheeler.compiler.packages.semver_prerelease_validation;

import wheeler.compiler.packages.semver_core_validation;

classical class SemverPrereleaseValidation {
  private long prereleaseLeadingMode(long partLength) {
    long invalid = 0;
    long valid = 1;
    if (partLength == 1) {
      return valid;
    }

    return invalid;
  }

  private long prereleaseNumericMode(long partLength, long first) {
    long valid = 1;
    long leadingMode = prereleaseLeadingMode(partLength);
    if (first == 48) {
      return leadingMode;
    }

    return valid;
  }

  private long prereleaseSeparatorMode(long partLength, long first, long numericPart) {
    long invalid = 0;
    long numeric = 1;
    long valid = 1;
    long numericMode = prereleaseNumericMode(partLength, first);
    if (partLength == 0) {
      return invalid;
    }

    if (numericPart == numeric) {
      return numericMode;
    }

    return valid;
  }

  private long prereleaseMode(
    long scalar,
    long mode,
    long partLength,
    long first,
    long numericPart
  ) {
    long invalid = 0;
    long valid = 1;
    long separatorMode = prereleaseSeparatorMode(partLength, first, numericPart);
    boolean allowed = semverIdentifierScalar(scalar);
    if (mode == invalid) {
      return invalid;
    }

    if (scalar == 46) {
      return separatorMode;
    }

    if (allowed == true) {
      return valid;
    }

    return invalid;
  }

  private long prereleasePartLength(long scalar, long partLength) {
    long zero = 0;
    long next = partLength + 1;
    if (scalar == 46) {
      return zero;
    }

    return next;
  }

  private long prereleaseFirst(long scalar, long partLength, long first) {
    long zero = 0;
    if (scalar == 46) {
      return zero;
    }

    if (partLength == 0) {
      return scalar;
    }

    return first;
  }

  private long prereleaseNumericPart(long scalar, long numericPart) {
    long numeric = 1;
    long mixed = 2;
    if (scalar == 46) {
      return numeric;
    }

    boolean digit = semverDigit(scalar);
    if (digit == true) {
      return numericPart;
    }

    return mixed;
  }

  private boolean prereleaseComplete(long mode, long partLength, long first, long numericPart) {
    long valid = 1;
    long finalMode = prereleaseSeparatorMode(partLength, first, numericPart);
    if (mode < valid) {
      return false;
    }

    if (valid < mode) {
      return false;
    }

    return finalMode == valid;
  }

  private boolean validPrerelease(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long mode = 1;
    long partLength = 0;
    long first = 0;
    long numericPart = 1;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextMode = prereleaseMode(scalar, mode, partLength, first, numericPart);
      long nextPartLength = prereleasePartLength(scalar, partLength);
      long nextFirst = prereleaseFirst(scalar, partLength, first);
      long nextNumericPart = prereleaseNumericPart(scalar, numericPart);
      mode = nextMode;
      partLength = nextPartLength;
      first = nextFirst;
      numericPart = nextNumericPart;
      cursor += width;
    }

    boolean complete = prereleaseComplete(mode, partLength, first, numericPart);
    return complete;
  }

  private long releaseCursor(long scalar, long cursor, long width, long end) {
    long next = cursor + width;
    if (scalar == 45) {
      return end;
    }

    return next;
  }

  private long releaseCoreLength(long scalar, long cursor, long start, long coreLength) {
    long candidate = cursor - start;
    if (scalar == 45) {
      return candidate;
    }

    return coreLength;
  }

  private long releasePrereleaseStart(long scalar, long cursor, long prereleaseStart) {
    long candidate = cursor + 1;
    if (scalar == 45) {
      return candidate;
    }

    return prereleaseStart;
  }

  private long releasePrereleaseState(long scalar, long state) {
    long found = 1;
    if (state == found) {
      return found;
    }

    if (scalar == 45) {
      return found;
    }

    return state;
  }

  private boolean releaseComplete(boolean core, long prereleaseState, boolean prerelease) {
    if (core == false) {
      return false;
    }

    if (prereleaseState == 1) {
      return prerelease;
    }

    return true;
  }

  /// Checks whether `release` satisfies the canonical profile.
  public boolean semverValidRelease(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long coreLength = length;
    long prereleaseStart = end;
    long prereleaseState = 0;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextCursor = releaseCursor(scalar, cursor, width, end);
      long nextCoreLength = releaseCoreLength(scalar, cursor, start, coreLength);
      long nextPrereleaseStart = releasePrereleaseStart(scalar, cursor, prereleaseStart);
      long nextPrereleaseState = releasePrereleaseState(scalar, prereleaseState);
      cursor = nextCursor;
      coreLength = nextCoreLength;
      prereleaseStart = nextPrereleaseStart;
      prereleaseState = nextPrereleaseState;
    }

    boolean core = semverValidCore(source, start, coreLength);
    long prereleaseLength = end - prereleaseStart;
    boolean prerelease = validPrerelease(source, prereleaseStart, prereleaseLength);
    boolean complete = releaseComplete(core, prereleaseState, prerelease);
    return complete;
  }

  private boolean prefixedRelease(borrow utf8 source, long start, long length) {
    if (length == 1) {
      return false;
    }

    long releaseStart = start + 1;
    long releaseLength = length - 1;
    boolean release = semverValidRelease(source, releaseStart, releaseLength);
    return release;
  }

  private boolean constraintResult(long scalar, boolean prefixed, boolean release) {
    if (scalar == 61) {
      return prefixed;
    }

    if (scalar == 94) {
      return prefixed;
    }

    if (scalar == 126) {
      return prefixed;
    }

    return release;
  }

  /// Checks whether `constraint` satisfies the canonical profile.
  public boolean semverValidConstraint(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long scalar = utf8Scalar(source, start);
    boolean prefixed = prefixedRelease(source, start, length);
    boolean release = semverValidRelease(source, start, length);
    boolean valid = constraintResult(scalar, prefixed, release);
    return valid;
  }
}
