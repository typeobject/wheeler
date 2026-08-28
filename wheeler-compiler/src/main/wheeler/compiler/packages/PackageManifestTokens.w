//! Classifies and compares package-manifest token ranges.

module wheeler.compiler.packages.manifest_tokens;

classical class ManifestTokens {
  /// Computes the stable hash of one bounded token range.
  public long tokenHash(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long cursor = starts[token];
    long length = lengths[token];
    long end = cursor + length;
    long hash = 0;
    while (cursor < end) limit 16 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long product = hash * 31;
      long nextHash = product + scalar;
      hash = nextHash;
      cursor += width;
    }

    return hash;
  }

  /// Checks whether one token carries the requested keyword hash.
  public boolean keywordAt(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token,
    long hash
  ) {
    long actual = tokenHash(source, starts, lengths, token);
    return actual == hash;
  }

  /// Checks whether `tokenText` denotes the same canonical value.
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

  /// Compares `tokenText` under canonical byte ordering.
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

  /// Computes the stable hash inside one quoted token.
  public long quotedHash(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long start = starts[token];
    long length = lengths[token];
    long cursor = start + 1;
    long endOffset = length - 1;
    long end = start + endOffset;
    long hash = 0;
    while (cursor < end) limit 32 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long product = hash * 31;
      long nextHash = product + scalar;
      hash = nextHash;
      cursor += width;
    }

    return hash;
  }

  /// Checks whether one token is a quoted ASCII value.
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

  /// Checks whether one token is a YAML mapping colon.
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

  /// Checks whether one token is a YAML sequence dash.
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
