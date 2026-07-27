//! Parses canonical repository snapshots into caller-owned coordinate tables.

module wheeler.packages.snapshot;

import wheeler.packages.semver;
import wheeler.packages.tokens;

classical class RepositorySnapshots {
  /// Names the number of words in one snapshot release row.
  public const long SNAPSHOT_ROW_WIDTH = 8;
  /// Names the package start column.
  public const long SNAPSHOT_PACKAGE_START = 0;
  /// Names the package length column.
  public const long SNAPSHOT_PACKAGE_LENGTH = 1;
  /// Names the version start column.
  public const long SNAPSHOT_VERSION_START = 2;
  /// Names the version length column.
  public const long SNAPSHOT_VERSION_LENGTH = 3;
  /// Names the archive start column.
  public const long SNAPSHOT_ARCHIVE_START = 4;
  /// Names the archive length column.
  public const long SNAPSHOT_ARCHIVE_LENGTH = 5;
  /// Names the manifest start column.
  public const long SNAPSHOT_MANIFEST_START = 6;
  /// Names the manifest length column.
  public const long SNAPSHOT_MANIFEST_LENGTH = 7;

  /// Describes a validated snapshot table.
  public record SnapshotModel(long releaseCount) {}

  /// Defines the closed snapshot parser result.
  public variant SnapshotResult {
    case Value(SnapshotModel snapshot);
    case Error(long offset);
  }

  private boolean punctuation(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long count,
    long token,
    long scalar
  ) {
    if (token < count) {
      if (kinds[token] == 3) {
        return utf8Scalar(source, starts[token]) == scalar;
      }
    }

    return false;
  }

  private boolean key(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long token,
    long hash
  ) {
    if (token + 1 < count) {
      if (keywordAt(source, starts, lengths, token, hash)) {
        return punctuation(source, kinds, starts, count, token + 1, 58);
      }
    }

    return false;
  }

  private boolean packageScalar(long scalar, boolean first) {
    if (96 < scalar) {
      if (scalar < 123) {
        return true;
      }
    }

    if (first == false) {
      if (47 < scalar) {
        if (scalar < 58) {
          return true;
        }
      }

      return scalar == 46;
    }

    return false;
  }

  private boolean validPackage(borrow utf8 source, long start, long length) {
    if (length == 0) {
      return false;
    }

    long cursor = start;
    long end = start + length;
    boolean first = true;
    boolean componentFirst = true;
    while (cursor < end) limit 4096 {
      long scalar = utf8Scalar(source, cursor);
      if (packageScalar(scalar, componentFirst) == false) {
        return false;
      }

      componentFirst = scalar == 46;
      if (componentFirst) {
        if (first) {
          return false;
        }
      }

      first = false;
      cursor += utf8Width(source, cursor);
    }

    return componentFirst == false;
  }

  private boolean validIdentity(borrow utf8 source, long start, long length) {
    if (length < 64) {
      return false;
    }

    if (64 < length) {
      return false;
    }

    long cursor = start;
    long end = start + length;
    while (cursor < end) limit 64 {
      long scalar = utf8Scalar(source, cursor);
      boolean digit = 47 < scalar;
      if (digit) {
        digit = scalar < 58;
      }

      boolean lowerHex = 96 < scalar;
      if (lowerHex) {
        lowerHex = scalar < 103;
      }

      if (digit == false) {
        if (lowerHex == false) {
          return false;
        }
      }

      cursor += utf8Width(source, cursor);
    }

    return true;
  }

  private boolean lineFeedAt(borrow utf8 source, long offset) {
    if (offset < bufferLength(source)) {
      return utf8Scalar(source, offset) == 10;
    }

    return false;
  }

  private record ReleaseParse(
    long next,
    long packageToken,
    long versionToken,
    long archiveToken,
    long manifestToken,
    boolean valid
  ) {}

  private ReleaseParse release(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor,
    long lineStart
  ) {
    ReleaseParse invalid = new ReleaseParse(cursor, 0, 0, 0, 0, false);
    if (cursor + 12 < count) {} else {
      return invalid;
    }

    if (starts[cursor] == lineStart + 2) {} else {
      return invalid;
    }

    if (key(source, kinds, starts, lengths, count, cursor + 1, 102272152646)) {} else {
      return invalid;
    }

    if (starts[cursor + 1] == lineStart + 4) {} else {
      return invalid;
    }

    if (starts[cursor + 2] == lineStart + 11) {} else {
      return invalid;
    }

    long packageToken = cursor + 3;
    if (starts[packageToken] == lineStart + 13) {} else {
      return invalid;
    }

    if (quoted(kinds, lengths, packageToken)) {} else {
      return invalid;
    }

    long packageEnd = starts[packageToken] + lengths[packageToken];
    if (lineFeedAt(source, packageEnd)) {} else {
      return invalid;
    }

    if (validPackage(source, starts[packageToken] + 1, lengths[packageToken] - 2)) {} else {
      return invalid;
    }

    long versionLine = packageEnd + 1;
    if (key(source, kinds, starts, lengths, count, cursor + 4, 107725790424)) {} else {
      return invalid;
    }

    if (starts[cursor + 4] == versionLine + 4) {} else {
      return invalid;
    }

    if (starts[cursor + 5] == versionLine + 11) {} else {
      return invalid;
    }

    long versionToken = cursor + 6;
    if (starts[versionToken] == versionLine + 13) {} else {
      return invalid;
    }

    if (quoted(kinds, lengths, versionToken)) {} else {
      return invalid;
    }

    long versionEnd = starts[versionToken] + lengths[versionToken];
    if (lineFeedAt(source, versionEnd)) {} else {
      return invalid;
    }

    if (validRelease(source, starts[versionToken] + 1, lengths[versionToken] - 2)) {} else {
      return invalid;
    }

    long archiveLine = versionEnd + 1;
    if (key(source, kinds, starts, lengths, count, cursor + 7, 89446211778)) {} else {
      return invalid;
    }

    if (starts[cursor + 7] == archiveLine + 4) {} else {
      return invalid;
    }

    if (starts[cursor + 8] == archiveLine + 11) {} else {
      return invalid;
    }

    long archiveToken = cursor + 9;
    if (starts[archiveToken] == archiveLine + 13) {} else {
      return invalid;
    }

    if (quoted(kinds, lengths, archiveToken)) {} else {
      return invalid;
    }

    long archiveEnd = starts[archiveToken] + lengths[archiveToken];
    if (lineFeedAt(source, archiveEnd)) {} else {
      return invalid;
    }

    if (validIdentity(source, starts[archiveToken] + 1, lengths[archiveToken] - 2)) {} else {
      return invalid;
    }

    long manifestLine = archiveEnd + 1;
    if (key(source, kinds, starts, lengths, count, cursor + 10, 3088212110895)) {} else {
      return invalid;
    }

    if (starts[cursor + 10] == manifestLine + 4) {} else {
      return invalid;
    }

    if (starts[cursor + 11] == manifestLine + 12) {} else {
      return invalid;
    }

    long manifestToken = cursor + 12;
    if (starts[manifestToken] == manifestLine + 14) {} else {
      return invalid;
    }

    if (quoted(kinds, lengths, manifestToken)) {} else {
      return invalid;
    }

    long manifestEnd = starts[manifestToken] + lengths[manifestToken];
    if (lineFeedAt(source, manifestEnd)) {} else {
      return invalid;
    }

    if (validIdentity(source, starts[manifestToken] + 1, lengths[manifestToken] - 2)) {} else {
      return invalid;
    }

    return new ReleaseParse(
      cursor + 13,
      packageToken,
      versionToken,
      archiveToken,
      manifestToken,
      true
    );
  }

  /// Parses every canonical coordinate that fits the caller-owned row table.
  public SnapshotResult parseSnapshot(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    borrow mut words rows
  ) {
    if (count < 7) {
      return new SnapshotResult.Error(0);
    }

    if (key(source, kinds, starts, lengths, count, 0, 3386979745)) {} else {
      return new SnapshotResult.Error(0);
    }

    if (tokenHash(source, starts, lengths, 2) == 49) {} else {
      return new SnapshotResult.Error(starts[2]);
    }

    if (key(source, kinds, starts, lengths, count, 3, 3229264107852)) {} else {
      return new SnapshotResult.Error(starts[3]);
    }

    if (count == 7) {
      if (starts[5] == 20) {} else {
        return new SnapshotResult.Error(starts[5]);
      }

      if (starts[6] == 21) {} else {
        return new SnapshotResult.Error(starts[6]);
      }

      if (utf8Scalar(source, 20) == 91) {} else {
        return new SnapshotResult.Error(20);
      }

      if (utf8Scalar(source, 21) == 93) {} else {
        return new SnapshotResult.Error(21);
      }

      if (lineFeedAt(source, 22)) {} else {
        return new SnapshotResult.Error(22);
      }

      if (bufferLength(source) == 23) {} else {
        return new SnapshotResult.Error(23);
      }

      return new SnapshotResult.Value(new SnapshotModel(0));
    }

    long cursor = 5;
    long lineStart = 20;
    long releaseCount = 0;
    long previousPackage = -1;
    long previousVersion = -1;
    while (cursor < count) limit 10000 {
      if (punctuation(source, kinds, starts, count, cursor, 45) == false) {
        return new SnapshotResult.Error(starts[cursor]);
      }

      if ((releaseCount + 1) * SNAPSHOT_ROW_WIDTH < bufferLength(rows) + 1) {} else {
        return new SnapshotResult.Error(starts[cursor]);
      }

      ReleaseParse parsed = release(source, kinds, starts, lengths, count, cursor, lineStart);
      if (parsed.valid == false) {
        return new SnapshotResult.Error(starts[cursor]);
      }

      if (-1 < previousPackage) {
        long packageOrder = compareTokenText(
          source,
          starts,
          lengths,
          previousPackage,
          parsed.packageToken
        );
        if (packageOrder < 0) {} else {
          if (packageOrder == 0) {
            long versionOrder = compareReleases(
              source,
              starts[previousVersion] + 1,
              lengths[previousVersion] - 2,
              starts[parsed.versionToken] + 1,
              lengths[parsed.versionToken] - 2
            );
            if (versionOrder < 0) {} else {
              return new SnapshotResult.Error(starts[parsed.versionToken]);
            }
          } else {
            return new SnapshotResult.Error(starts[parsed.packageToken]);
          }
        }
      }

      long row = releaseCount * SNAPSHOT_ROW_WIDTH;
      set(rows, row + SNAPSHOT_PACKAGE_START, starts[parsed.packageToken] + 1);
      set(rows, row + SNAPSHOT_PACKAGE_LENGTH, lengths[parsed.packageToken] - 2);
      set(rows, row + SNAPSHOT_VERSION_START, starts[parsed.versionToken] + 1);
      set(rows, row + SNAPSHOT_VERSION_LENGTH, lengths[parsed.versionToken] - 2);
      set(rows, row + SNAPSHOT_ARCHIVE_START, starts[parsed.archiveToken] + 1);
      set(rows, row + SNAPSHOT_ARCHIVE_LENGTH, lengths[parsed.archiveToken] - 2);
      set(rows, row + SNAPSHOT_MANIFEST_START, starts[parsed.manifestToken] + 1);
      set(rows, row + SNAPSHOT_MANIFEST_LENGTH, lengths[parsed.manifestToken] - 2);
      previousPackage = parsed.packageToken;
      previousVersion = parsed.versionToken;
      releaseCount += 1;
      cursor = parsed.next;
      lineStart = starts[parsed.manifestToken] + lengths[parsed.manifestToken] + 1;
    }

    if (releaseCount == 0) {
      return new SnapshotResult.Error(0);
    }

    if (lineStart == bufferLength(source)) {} else {
      return new SnapshotResult.Error(lineStart);
    }

    return new SnapshotResult.Value(new SnapshotModel(releaseCount));
  }
}
