//! Matches exact words in canonical lock, workspace, and repository metadata.

module wheeler.packages.metadata_tokens;

import wheeler.compiler.packages.manifest_tokens;

classical class MetadataTokens {
  /// Names the workspace opener outside the package-manifest vocabulary.
  public const long METADATA_WORD_WORKSPACE = -1;
  /// Names the workspace member collection.
  public const long METADATA_WORD_MEMBERS = -2;
  /// Names the lock package collection.
  public const long METADATA_WORD_PACKAGES = -3;
  /// Names a locked repository identity.
  public const long METADATA_WORD_REPOSITORY = -4;
  /// Names a locked snapshot identity.
  public const long METADATA_WORD_SNAPSHOT = -5;
  /// Names an archive identity.
  public const long METADATA_WORD_ARCHIVE = -6;
  /// Names a manifest identity.
  public const long METADATA_WORD_MANIFEST = -7;
  /// Names a snapshot release collection.
  public const long METADATA_WORD_RELEASES = -8;
  /// Names the exact lock schema scalar `3`.
  public const long METADATA_WORD_SCHEMA_THREE = -9;

  // The first eight ASCII scalars occupy a little-endian base-128 lane.
  // The remaining scalars occupy the tail. Exact length excludes leading NUL aliases.
  private boolean additionalWordEquals(
    borrow utf8 source,
    long start,
    long length,
    long expectedLength,
    long head,
    long tail
  ) {
    if (length != expectedLength) {
      return false;
    }
    if (start < 0) {
      return false;
    }
    if (bufferLength(source) - length < start) {
      return false;
    }
    long offset = 0;
    while (offset < length) limit 12 {
      long wanted = head % 128;
      if (offset < 8) {
        head = head / 128;
      } else {
        wanted = tail % 128;
        tail = tail / 128;
      }
      if (utf8Scalar(source, start + offset) != wanted) {
        return false;
      }
      offset += 1;
    }
    return true;
  }

  /// Matches a positive manifest code or a negative metadata-only code. Zero never matches.
  public boolean metadataTokenEquals(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token,
    long expected
  ) {
    if (expected == 0) {
      return false;
    }
    if (expected < METADATA_WORD_SCHEMA_THREE) {
      return false;
    }
    if (token < 0) {
      return false;
    }
    if (bufferLength(starts) - 1 < token) {
      return false;
    }
    if (bufferLength(lengths) - 1 < token) {
      return false;
    }
    if (0 < expected) {
      return manifestTokenWord(source, starts, lengths, token) == expected;
    }
    long start = starts[token];
    long length = lengths[token];
    if (expected == METADATA_WORD_WORKSPACE) {
      return additionalWordEquals(source, start, length, 9, 56162535287338999, 101);
    }
    if (expected == METADATA_WORD_MEMBERS) {
      return additionalWordEquals(source, start, length, 7, 509719678251757, 0);
    }
    if (expected == METADATA_WORD_PACKAGES) {
      return additionalWordEquals(source, start, length, 8, 65187012658393328, 0);
    }
    if (expected == METADATA_WORD_REPOSITORY) {
      return additionalWordEquals(source, start, length, 10, 63001257102291698, 15602);
    }
    if (expected == METADATA_WORD_SNAPSHOT) {
      return additionalWordEquals(source, start, length, 8, 65793982278956915, 0);
    }
    if (expected == METADATA_WORD_ARCHIVE) {
      return additionalWordEquals(source, start, length, 7, 448285552212321, 0);
    }
    if (expected == METADATA_WORD_MANIFEST) {
      return additionalWordEquals(source, start, length, 8, 65811467881656557, 0);
    }
    if (expected == METADATA_WORD_RELEASES) {
      return additionalWordEquals(source, start, length, 8, 65187424962818802, 0);
    }
    return additionalWordEquals(source, start, length, 1, 51, 0);
  }

  /// Checks a complete identifier-and-colon pair before accepting its exact word.
  public boolean metadataKeyAt(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long token,
    long expected
  ) {
    if (token < 0) {
      return false;
    }
    if (count < 2) {
      return false;
    }
    if (count - 2 < token) {
      return false;
    }
    if (bufferLength(kinds) < count) {
      return false;
    }
    if (bufferLength(starts) < count) {
      return false;
    }
    if (bufferLength(lengths) < count) {
      return false;
    }
    if (kinds[token] != 1) {
      return false;
    }
    if (metadataTokenEquals(source, starts, lengths, token, expected) == false) {
      return false;
    }
    return colonAt(source, kinds, starts, token + 1);
  }
}
