//! Indexes validated source entries in one canonical package archive.

module wheeler.compiler.closure.archive_sources;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;

classical class ArchiveSources {
  private const long ARCHIVE_DIGEST_BYTES = 32;
  private const long ARCHIVE_HASH_ARENA_BYTES = 600000;
  private const long ARCHIVE_INDEX_ARENA_BYTES = 16456;
  private const long ENTRY_COUNT_LIMIT = 513;
  private const long ENTRY_HEADER_BYTES = 12;
  private const long MAX_ARCHIVE_BYTES = 16777216;
  private const long MAX_ARCHIVE_ENTRIES = 512;
  private const long MAX_MANIFEST_BYTES = 262144;
  private const long MAX_PATH_BYTES = 4096;

  /// Carries immutable bounds for one validated archive source index.
  public record ArchiveSourceIndex(
    long manifestStart,
    long manifestLength,
    long entryCount,
    long payloadLength
  ) {}

  /// Defines the closed archive-index result cases.
  public variant ArchiveSourceIndexResult {
    case Value(ArchiveSourceIndex index);
    case Error(long offset);
  }

  private boolean archiveMagicValid(borrow byteview source) {
    if (source[0] == 87) {
      if (source[1] == 80) {
        if (source[2] == 75) {
          if (source[3] == 71) {
            if (source[4] == 0) {
              if (source[5] == 0) {
                if (source[6] == 0) {
                  return source[7] == 1;
                }
              }
            }
          }
        }
      }
    }

    return false;
  }

  private boolean digestMatches(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    long digestStart,
    borrow mut bytes digest,
    borrow mut region arena
  ) {
    hashSha256Range(source, sourceStart, sourceLength, digest, arena);
    long cursor = 0;
    while (cursor < ARCHIVE_DIGEST_BYTES) limit ARCHIVE_DIGEST_BYTES {
      if (digest[cursor] == source[digestStart + cursor]) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private boolean pathCharacter(long value) {
    if (44 < value) {
      if (value < 58) {
        return value != 47;
      }
    }

    if (64 < value) {
      if (value < 91) {
        return true;
      }
    }

    if (96 < value) {
      if (value < 123) {
        return true;
      }
    }

    return value == 95;
  }

  private boolean canonicalPath(borrow byteview source, long start, long length) {
    if (0 < length) {} else {
      return false;
    }

    if (length < MAX_PATH_BYTES + 1) {} else {
      return false;
    }

    long segmentLength = 0;
    boolean segmentDots = true;
    long cursor = 0;
    while (cursor < length) limit MAX_PATH_BYTES {
      long value = source[start + cursor];
      if (value == 47) {
        if (0 < segmentLength) {} else {
          return false;
        }

        if (segmentDots) {
          if (segmentLength < 3) {
            return false;
          }
        }

        segmentLength = 0;
        segmentDots = true;
      } else {
        if (pathCharacter(value)) {} else {
          return false;
        }

        if (value == 46) {} else {
          segmentDots = false;
        }

        segmentLength += 1;
      }

      cursor += 1;
    }

    if (0 < segmentLength) {} else {
      return false;
    }

    if (segmentDots) {
      return 2 < segmentLength;
    }

    return true;
  }

  private boolean columnsValid(
    borrow mut words pathStarts,
    borrow mut words pathLengths,
    borrow mut words dataStarts,
    borrow mut words dataLengths
  ) {
    if (bufferLength(pathStarts) == MAX_ARCHIVE_ENTRIES) {} else {
      return false;
    }

    if (bufferLength(pathLengths) == MAX_ARCHIVE_ENTRIES) {} else {
      return false;
    }

    if (bufferLength(dataStarts) == MAX_ARCHIVE_ENTRIES) {} else {
      return false;
    }

    return bufferLength(dataLengths) == MAX_ARCHIVE_ENTRIES;
  }

  /// Validates one archive completely before publishing exact source-entry offsets.
  public ArchiveSourceIndexResult indexArchiveSources(
    borrow byteview source,
    borrow mut words pathStarts,
    borrow mut words pathLengths,
    borrow mut words dataStarts,
    borrow mut words dataLengths
  ) {
    long fileLength = bufferLength(source);
    if (63 < fileLength) {} else {
      return new ArchiveSourceIndexResult.Error(0);
    }

    if (fileLength < MAX_ARCHIVE_BYTES + 1) {} else {
      return new ArchiveSourceIndexResult.Error(MAX_ARCHIVE_BYTES);
    }

    if (columnsValid(pathStarts, pathLengths, dataStarts, dataLengths)) {} else {
      return new ArchiveSourceIndexResult.Error(0);
    }

    if (archiveMagicValid(source)) {} else {
      return new ArchiveSourceIndexResult.Error(0);
    }

    long manifestLength = readUnsigned(source, 8, 4);
    long entryCount = readUnsigned(source, 12, 4);
    if (0 < manifestLength) {} else {
      return new ArchiveSourceIndexResult.Error(8);
    }

    if (manifestLength < MAX_MANIFEST_BYTES + 1) {} else {
      return new ArchiveSourceIndexResult.Error(8);
    }

    if (0 < entryCount) {} else {
      return new ArchiveSourceIndexResult.Error(12);
    }

    if (entryCount < ENTRY_COUNT_LIMIT) {} else {
      return new ArchiveSourceIndexResult.Error(12);
    }

    long payloadLength = fileLength - ARCHIVE_DIGEST_BYTES;
    long cursor = 16 + manifestLength;
    if (cursor < payloadLength) {} else {
      return new ArchiveSourceIndexResult.Error(16);
    }

    region indexArena = new region(/* bytes= */ ARCHIVE_INDEX_ARENA_BYTES, /* allocations= */ 4);
    words scratchPathStarts = allocate(indexArena, MAX_ARCHIVE_ENTRIES);
    words scratchPathLengths = allocate(indexArena, MAX_ARCHIVE_ENTRIES);
    words scratchDataStarts = allocate(indexArena, MAX_ARCHIVE_ENTRIES);
    words scratchDataLengths = allocate(indexArena, MAX_ARCHIVE_ENTRIES);
    region hashArena = new region(/* bytes= */ ARCHIVE_HASH_ARENA_BYTES, /* allocations= */ 1540);
    bytes digest = allocateBytes(hashArena, ARCHIVE_DIGEST_BYTES);
    boolean valid = digestMatches(source, 0, payloadLength, payloadLength, digest, hashArena);
    long errorOffset = payloadLength;
    long entry = 0;
    long priorPathStart = 0;
    long priorPathLength = 0;
    while (entry < entryCount) limit MAX_ARCHIVE_ENTRIES {
      if (valid) {
        if (cursor + ENTRY_HEADER_BYTES < payloadLength + 1) {} else {
          valid = false;
          errorOffset = cursor;
        }
      }

      long pathLength = 0;
      long dataLength = 0;
      long pathStart = 0;
      long dataStart = 0;
      if (valid) {
        pathLength = readUnsigned(source, cursor, 4);
        long dataLengthOffset = cursor + 4;
        if (source[dataLengthOffset + 4] == 0) {} else {
          valid = false;
          errorOffset = dataLengthOffset + 4;
        }

        if (source[dataLengthOffset + 5] == 0) {} else {
          valid = false;
          errorOffset = dataLengthOffset + 5;
        }

        if (source[dataLengthOffset + 6] == 0) {} else {
          valid = false;
          errorOffset = dataLengthOffset + 6;
        }

        if (source[dataLengthOffset + 7] == 0) {} else {
          valid = false;
          errorOffset = dataLengthOffset + 7;
        }

        if (valid) {
          dataLength = readUnsigned(source, dataLengthOffset, 4);
          if (dataLength < MAX_ARCHIVE_BYTES + 1) {} else {
            valid = false;
            errorOffset = dataLengthOffset;
          }
        }

        if (0 < pathLength) {} else {
          valid = false;
          errorOffset = cursor;
        }

        if (pathLength < MAX_PATH_BYTES + 1) {} else {
          valid = false;
          errorOffset = cursor;
        }

        pathStart = cursor + ENTRY_HEADER_BYTES;
        dataStart = pathStart + pathLength + ARCHIVE_DIGEST_BYTES;
        if (valid) {
          if (dataStart + dataLength < payloadLength + 1) {} else {
            valid = false;
            errorOffset = cursor;
          }
        }
      }

      if (valid) {
        valid = canonicalPath(source, pathStart, pathLength);
        if (valid) {} else {
          errorOffset = pathStart;
        }
      }

      if (valid) {
        if (0 < entry) {
          if (
            compareAsciiRanges(source, priorPathStart, priorPathLength, pathStart, pathLength) < 0
          ) {} else {
            valid = false;
            errorOffset = pathStart;
          }
        }
      }

      if (valid) {
        valid = digestMatches(
          source,
          dataStart,
          dataLength,
          pathStart + pathLength,
          digest,
          hashArena
        );
        if (valid) {} else {
          errorOffset = pathStart + pathLength;
        }
      }

      if (valid) {
        set(scratchPathStarts, entry, pathStart);
        set(scratchPathLengths, entry, pathLength);
        set(scratchDataStarts, entry, dataStart);
        set(scratchDataLengths, entry, dataLength);
        priorPathStart = pathStart;
        priorPathLength = pathLength;
        cursor = dataStart + dataLength;
      }

      entry += 1;
    }

    if (valid) {
      if (cursor == payloadLength) {} else {
        valid = false;
        errorOffset = cursor;
      }
    }

    long publish = 0;
    while (publish < MAX_ARCHIVE_ENTRIES) limit MAX_ARCHIVE_ENTRIES {
      if (valid) {
        set(pathStarts, publish, scratchPathStarts[publish]);
        set(pathLengths, publish, scratchPathLengths[publish]);
        set(dataStarts, publish, scratchDataStarts[publish]);
        set(dataLengths, publish, scratchDataLengths[publish]);
      }

      publish += 1;
    }

    drop(digest);
    drop(hashArena);
    drop(scratchDataLengths);
    drop(scratchDataStarts);
    drop(scratchPathLengths);
    drop(scratchPathStarts);
    drop(indexArena);
    if (valid) {
      ArchiveSourceIndex index = new ArchiveSourceIndex(
        /* manifestStart= */ 16,
        manifestLength,
        entryCount,
        payloadLength
      );
      return new ArchiveSourceIndexResult.Value(index);
    }

    return new ArchiveSourceIndexResult.Error(errorOffset);
  }
}
