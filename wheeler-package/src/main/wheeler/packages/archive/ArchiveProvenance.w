//! Binds one bounded canonical package archive to its exact lock entry.

module wheeler.packages.archive_provenance;

import wheeler.crypto.sha256;
import wheeler.packages.archive;

classical class ArchiveProvenance {
  private const long MAX_ARCHIVE_BYTES = 32768;
  private const long MAX_LOCK_BYTES = 4096;

  private long rangeHash(borrow byteview input, long start, long length) {
    long hash = 0;
    long offset = 0;
    while (offset < length) limit MAX_LOCK_BYTES {
      hash = (hash * 131 + input[start + offset]) % 4294967296;
      offset += 1;
    }

    return hash;
  }

  private long lineEnd(borrow byteview input, long cursor) {
    long scan = cursor;
    while (scan < bufferLength(input)) limit MAX_LOCK_BYTES {
      if (input[scan] == 10) {
        return scan;
      }

      if (input[scan] == 13) {
        return -1;
      }

      scan += 1;
    }

    return -1;
  }

  private boolean sameRange(
    borrow byteview left,
    long leftStart,
    borrow byteview right,
    long rightStart,
    long length
  ) {
    long offset = 0;
    while (offset < length) limit 255 {
      if (left[leftStart + offset] != right[rightStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long lockedIdentityStart(
    borrow byteview lock,
    borrow byteview packageName,
    long fieldOrdinal
  ) {
    long cursor = 0;
    while (cursor < bufferLength(lock)) limit MAX_LOCK_BYTES {
      long found = lineEnd(lock, cursor);
      if (found < 0) {
        return -1;
      }

      long nameLength = bufferLength(packageName);
      if (found - cursor == nameLength + 12) {
        if (rangeHash(lock, cursor, /* length= */ 11) == 586558766) {
          if (lock[found - 1] != 34) {
            return -1;
          }

          if (sameRange(lock, cursor + 11, packageName, /* rightStart= */ 0, nameLength)) {
            cursor = found + 1;
            long field = 1;
            while (field < fieldOrdinal) limit 5 {
              found = lineEnd(lock, cursor);
              if (found < 0) {
                return -1;
              }

              cursor = found + 1;
              field += 1;
            }

            found = lineEnd(lock, cursor);
            if (found < 0) {
              return -1;
            }

            long prefixLength = 14;
            long prefixHash = 2665284562;
            if (fieldOrdinal == 5) {
              prefixLength = 15;
              prefixHash = 3265168425;
            }

            if (found - cursor != prefixLength + 65) {
              return -1;
            }

            if (rangeHash(lock, cursor, prefixLength) != prefixHash) {
              return -1;
            }

            if (lock[found - 1] != 34) {
              return -1;
            }

            return cursor + prefixLength;
          }
        }
      }

      cursor = found + 1;
    }

    return -1;
  }

  private long hexadecimalNibble(long scalar) {
    if (47 < scalar) {
      if (scalar < 58) {
        return scalar - 48;
      }
    }

    if (96 < scalar) {
      if (scalar < 103) {
        return scalar - 87;
      }
    }

    return -1;
  }

  private boolean digestMatchesHex(
    borrow byteview digest,
    borrow byteview text,
    long textStart
  ) {
    long offset = 0;
    while (offset < 32) limit 32 {
      long high = hexadecimalNibble(text[textStart + offset * 2]);
      long low = hexadecimalNibble(text[textStart + offset * 2 + 1]);
      if (high < 0) {
        return false;
      }

      if (low < 0) {
        return false;
      }

      if (digest[offset] != high * 16 + low) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private boolean manifestNamesPackage(
    borrow byteview archive,
    long manifestLength,
    borrow byteview packageName
  ) {
    long nameLength = bufferLength(packageName);
    if (manifestLength < 29 + nameLength) {
      return false;
    }

    if (rangeHash(archive, /* start= */ 16, /* length= */ 28) != 2409422451) {
      return false;
    }

    if (sameRange(archive, /* leftStart= */ 44, packageName, /* rightStart= */ 0, nameLength)
        == false) {
      return false;
    }

    return archive[44 + nameLength] == 34;
  }

  /// Validates archive structure and binds its package, manifest, and full identity to one lock row.
  public boolean validLockedArchive(
    borrow byteview lock,
    borrow byteview packageName,
    borrow byteview archive,
    borrow mut bytes digest,
    borrow mut region arena
  ) {
    if (bufferLength(lock) < 96) {
      return false;
    }

    if (MAX_LOCK_BYTES < bufferLength(lock)) {
      return false;
    }

    if (bufferLength(packageName) < 1) {
      return false;
    }

    if (255 < bufferLength(packageName)) {
      return false;
    }

    if (MAX_ARCHIVE_BYTES < bufferLength(archive)) {
      return false;
    }

    if (bufferLength(digest) != 32) {
      return false;
    }

    long archiveIdentityStart = lockedIdentityStart(lock, packageName, /* fieldOrdinal= */ 4);
    long manifestIdentityStart = lockedIdentityStart(lock, packageName, /* fieldOrdinal= */ 5);
    if (archiveIdentityStart < 0) {
      return false;
    }

    if (manifestIdentityStart < 0) {
      return false;
    }

    ArchiveResult inspected = inspectArchive(archive, digest, arena);
    long manifestLength = 0;
    boolean valid = false;
    match (inspected) {
      case ArchiveResult.Value(ArchiveModel model) {
        manifestLength = model.manifestLength;
        valid = true;
      }
      case ArchiveResult.Error(long offset) {
        valid = false;
      }
    }

    if (valid == false) {
      return false;
    }

    if (manifestNamesPackage(archive, manifestLength, packageName) == false) {
      return false;
    }

    hashSha256Range(
      archive,
      /* sourceStart= */ 0,
      bufferLength(archive),
      digest,
      arena
    );
    if (digestMatchesHex(digest, lock, archiveIdentityStart) == false) {
      return false;
    }

    hashSha256Range(archive, /* sourceStart= */ 16, manifestLength, digest, arena);
    return digestMatchesHex(digest, lock, manifestIdentityStart);
  }
}
