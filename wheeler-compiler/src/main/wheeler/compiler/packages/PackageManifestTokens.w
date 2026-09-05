//! Classifies scanner-owned manifest tokens and compares their ranges.

module wheeler.compiler.packages.manifest_tokens;

import wheeler.compiler.packages.manifest_words;

classical class ManifestTokens {
  /// Classifies a scanner token, or returns zero for an unknown word.
  public long manifestTokenWord(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long start = starts[token];
    long length = lengths[token];
    long word = manifestRangeWord(source, start, length);
    return word;
  }

  /// Classifies the interior of a scanner-validated quoted token.
  public long manifestQuotedWord(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long start = starts[token];
    long length = lengths[token];
    if (start < 0) {
      return 0;
    }
    if (length < 3) {
      return 0;
    }
    long capacity = bufferLength(source);
    long lastStart = capacity - length;
    if (lastStart < start) {
      return 0;
    }
    long interiorStart = start + 1;
    long interiorLength = length - 2;
    long word = manifestRangeWord(source, interiorStart, interiorLength);
    return word;
  }

  /// Checks whether two scanner tokens have identical text.
  public boolean sameTokenText(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long left,
    long right
  ) {
    long leftLength = lengths[left];
    long rightLength = lengths[right];
    if (leftLength < rightLength) {
      return false;
    }
    if (rightLength < leftLength) {
      return false;
    }
    long leftStart = starts[left];
    long rightStart = starts[right];
    boolean same = true;
    long offset = 0;
    while (offset < leftLength) limit 4096 {
      long leftIndex = leftStart + offset;
      long rightIndex = rightStart + offset;
      long leftScalar = utf8Scalar(source, leftIndex);
      long rightScalar = utf8Scalar(source, rightIndex);
      if (leftScalar < rightScalar) {
        same = false;
      }
      if (rightScalar < leftScalar) {
        same = false;
      }
      offset += 1;
    }
    return same;
  }

  private long minimumLength(long left, long right) {
    if (left < right) {
      return left;
    }
    return right;
  }

  /// Compares scanner tokens under canonical byte ordering.
  public long compareTokenText(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long left,
    long right
  ) {
    long leftLength = lengths[left];
    long rightLength = lengths[right];
    long leftStart = starts[left];
    long rightStart = starts[right];
    long comparison = leftLength - rightLength;
    long offset = 0;
    long commonLength = minimumLength(leftLength, rightLength);
    long reverse = commonLength;
    while (offset < commonLength) limit 4096 {
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
    return comparison;
  }

  /// Checks whether one scanner token is a nonempty quoted ASCII value.
  public boolean quoted(borrow mut words kinds, borrow mut words lengths, long token) {
    long kind = kinds[token];
    long length = lengths[token];
    long quotedKind = 6;
    long minimumLength = 2;
    if (kind < quotedKind) {
      return false;
    }
    if (quotedKind < kind) {
      return false;
    }
    return minimumLength < length;
  }

  /// Checks whether one scanner token is a YAML mapping colon.
  public boolean colonAt(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long token
  ) {
    long kind = kinds[token];
    long start = starts[token];
    long scalar = utf8Scalar(source, start);
    long punctuationKind = 3;
    long colon = 58;
    if (kind < punctuationKind) {
      return false;
    }
    if (punctuationKind < kind) {
      return false;
    }
    if (scalar < colon) {
      return false;
    }
    if (colon < scalar) {
      return false;
    }
    return true;
  }

  /// Checks whether one scanner token is a YAML sequence dash.
  public boolean dashAt(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long token
  ) {
    long kind = kinds[token];
    long start = starts[token];
    long scalar = utf8Scalar(source, start);
    long punctuationKind = 3;
    long dash = 45;
    if (kind < punctuationKind) {
      return false;
    }
    if (punctuationKind < kind) {
      return false;
    }
    if (scalar < dash) {
      return false;
    }
    if (dash < scalar) {
      return false;
    }
    return true;
  }
}
