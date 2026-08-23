//! Binds one bounded canonical package archive to its exact lock entry.

module wheeler.packages.archive_provenance;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.packages.archive;

classical class ArchiveProvenance {
  /// Identifies one path and source range inside a validated locked archive.
  public record LockedArchiveEntry(
    long pathStart,
    long pathLength,
    long sourceStart,
    long sourceLength
  ) {}
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

  private boolean exactLine(
    borrow byteview input,
    long start,
    long end,
    long length,
    long hash
  ) {
    if (end - start != length) {
      return false;
    }

    return rangeHash(input, start, length) == hash;
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

  private long lockedDependenciesStart(
    borrow byteview lock,
    borrow byteview packageName
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
            long field = 0;
            while (field < 5) limit 5 {
              found = lineEnd(lock, cursor);
              if (found < 0) {
                return -1;
              }

              cursor = found + 1;
              field += 1;
            }

            return cursor;
          }
        }
      }

      cursor = found + 1;
    }

    return -1;
  }

  /// Matches canonical normal dependency names in a validated archive and lock row.
  public boolean lockedArchiveDependenciesMatch(
    borrow byteview lock,
    borrow byteview packageName,
    borrow byteview archive
  ) {
    if (MAX_LOCK_BYTES < bufferLength(lock)) {
      return false;
    }

    if (bufferLength(archive) < 17) {
      return false;
    }

    long manifestLength = readUnsigned(archive, /* offset= */ 8, /* width= */ 4);
    long manifestEnd = 16 + manifestLength;
    if (bufferLength(archive) < manifestEnd) {
      return false;
    }

    long lockCursor = lockedDependenciesStart(lock, packageName);
    if (lockCursor < 0) {
      return false;
    }

    long lockEnd = lineEnd(lock, lockCursor);
    if (lockEnd < 0) {
      return false;
    }

    boolean emptyLock = exactLine(
      lock,
      lockCursor,
      lockEnd,
      /* length= */ 20,
      /* hash= */ 1528119609
    );
    if (emptyLock == false) {
      if (
        exactLine(
          lock,
          lockCursor,
          lockEnd,
          /* length= */ 17,
          /* hash= */ 1805921201
        ) == false
      ) {
        return false;
      }

      lockCursor = lockEnd + 1;
    }

    long manifestCursor = 16;
    long manifestLineEnd = -1;
    boolean foundDependencies = false;
    while (manifestCursor < manifestEnd) limit 4096 {
      manifestLineEnd = lineEnd(archive, manifestCursor);
      if (manifestLineEnd < 0) {
        return false;
      }

      if (manifestEnd < manifestLineEnd + 1) {
        return false;
      }

      if (
        exactLine(
          archive,
          manifestCursor,
          manifestLineEnd,
          /* length= */ 16,
          /* hash= */ 1399774265
        )
      ) {
        return emptyLock;
      }

      if (
        exactLine(
          archive,
          manifestCursor,
          manifestLineEnd,
          /* length= */ 13,
          /* hash= */ 344468657
        )
      ) {
        foundDependencies = true;
        manifestCursor = manifestLineEnd + 1;
        break;
      }

      manifestCursor = manifestLineEnd + 1;
    }

    if (foundDependencies == false) {
      return false;
    }

    if (emptyLock) {
      return false;
    }

    boolean scanning = true;
    while (scanning) limit 64 {
      if (manifestCursor < manifestEnd) {} else {
        return false;
      }

      manifestLineEnd = lineEnd(archive, manifestCursor);
      if (manifestLineEnd < 0) {
        return false;
      }

      boolean capabilities = exactLine(
        archive,
        manifestCursor,
        manifestLineEnd,
        /* length= */ 13,
        /* hash= */ 1665807620
      );
      if (capabilities == false) {
        capabilities = exactLine(
          archive,
          manifestCursor,
          manifestLineEnd,
          /* length= */ 16,
          /* hash= */ 2054217082
        );
      }

      if (capabilities) {
        scanning = false;
      } else {
        if (
          exactLine(
            archive,
            manifestCursor,
            manifestLineEnd,
            /* length= */ 18,
            /* hash= */ 3944386646
          ) == false
        ) {
          return false;
        }

        manifestCursor = manifestLineEnd + 1;
        manifestLineEnd = lineEnd(archive, manifestCursor);
        if (manifestLineEnd < 0) {
          return false;
        }

        if (manifestLineEnd - manifestCursor < 13) {
          return false;
        }

        if (rangeHash(archive, manifestCursor, /* length= */ 11) != 3709182977) {
          return false;
        }

        long nameLength = manifestLineEnd - manifestCursor - 12;
        if (archive[manifestLineEnd - 1] != 34) {
          return false;
        }

        lockEnd = lineEnd(lock, lockCursor);
        if (lockEnd < 0) {
          return false;
        }

        if (lockEnd - lockCursor != nameLength + 10) {
          return false;
        }

        if (rangeHash(lock, lockCursor, /* length= */ 9) != 1271526807) {
          return false;
        }

        if (lock[lockEnd - 1] != 34) {
          return false;
        }

        if (
          sameRange(
            archive,
            manifestCursor + 11,
            lock,
            lockCursor + 9,
            nameLength
          ) == false
        ) {
          return false;
        }

        manifestCursor = manifestLineEnd + 1;
        manifestLineEnd = lineEnd(archive, manifestCursor);
        if (manifestLineEnd < 0) {
          return false;
        }

        manifestCursor = manifestLineEnd + 1;
        lockCursor = lockEnd + 1;
      }
    }

    lockEnd = lineEnd(lock, lockCursor);
    if (lockEnd < 0) {
      return lockCursor == bufferLength(lock);
    }

    if (lockEnd - lockCursor < 9) {
      return true;
    }

    return rangeHash(lock, lockCursor, /* length= */ 9) != 1271526807;
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

  /// Returns one entry range after repeating complete archive and lock validation.
  public LockedArchiveEntry validatedLockedArchiveEntry(
    borrow byteview lock,
    borrow byteview packageName,
    borrow byteview archive,
    long ordinal,
    borrow mut bytes digest,
    borrow mut region arena
  ) {
    assert(validLockedArchive(lock, packageName, archive, digest, arena));
    long manifestLength = readUnsigned(archive, /* offset= */ 8, /* width= */ 4);
    long entryCount = readUnsigned(archive, /* offset= */ 12, /* width= */ 4);
    assert(ordinal < entryCount);
    long cursor = 16 + manifestLength;
    long entry = 0;
    while (entry < ordinal) limit 4 {
      long priorPathLength = readUnsigned(archive, cursor, /* width= */ 4);
      long priorSourceLength = readUnsigned(archive, cursor + 4, /* width= */ 8);
      cursor += 12 + priorPathLength + 32 + priorSourceLength;
      entry += 1;
    }

    long pathLength = readUnsigned(archive, cursor, /* width= */ 4);
    long sourceLength = readUnsigned(archive, cursor + 4, /* width= */ 8);
    long pathStart = cursor + 12;
    long sourceStart = pathStart + pathLength + 32;
    return new LockedArchiveEntry(pathStart, pathLength, sourceStart, sourceLength);
  }
}
