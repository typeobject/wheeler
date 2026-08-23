//! Validates bounded canonical package archive structure.

module wheeler.packages.archive;

import wheeler.compiler.packages.canonical;
import wheeler.compiler.packages.manifest;
import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.lexer.scanner;

classical class Archive {
  /// Carries the bounded canonical archive envelope.
  public record ArchiveModel(
    long manifestLength,
    long entryCount,
    long packageLength,
    long targetCount
  ) {}

  /// Identifies one path and source range inside a validated archive.
  public record ArchiveEntry(
    long pathStart,
    long pathLength,
    long sourceStart,
    long sourceLength
  ) {}

  /// Defines the closed archive inspection result.
  public variant ArchiveResult {
    case Value(ArchiveModel archive);
    case Error(long offset);
  }

  private const long MAX_ENTRIES = 4;

  private boolean magicValid(borrow byteview source) {
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
    while (cursor < 32) limit 32 {
      if (digest[cursor] == source[digestStart + cursor]) {
        cursor += 1;
      } else {
        return false;
      }
    }

    return true;
  }

  private boolean canonicalManifestEnvelope(borrow byteview source, long start, long length) {
    if (length == 0) {
      return false;
    }

    if (source[start + length - 1] == 10) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < length) limit 4096 {
      long value = source[start + cursor];
      if (value == 10) {} else {
        if (value < 32) {
          return false;
        }

        if (126 < value) {
          return false;
        }
      }

      cursor += 1;
    }

    return true;
  }

  private boolean pathMatchesManifest(
    borrow byteview source,
    long pathStart,
    long pathLength,
    borrow utf8 manifest,
    long expectedStart,
    long expectedLength
  ) {
    if (pathLength == expectedLength) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < pathLength) limit 4096 {
      if (source[pathStart + cursor] == utf8Scalar(manifest, expectedStart + cursor)) {
        cursor += 1;
      } else {
        return false;
      }
    }

    return true;
  }

  /// Projects one entry from an archive that already passed `inspectArchive`.
  public ArchiveEntry validatedArchiveEntry(
    borrow byteview source,
    long manifestLength,
    long ordinal
  ) {
    long entryCount = readUnsigned(source, /* offset= */ 12, /* width= */ 4);
    assert(ordinal < entryCount);
    assert(entryCount < MAX_ENTRIES + 1);
    long cursor = 16 + manifestLength;
    long entry = 0;
    while (entry < ordinal) limit MAX_ENTRIES {
      long priorPathLength = readUnsigned(source, cursor, /* width= */ 4);
      long priorSourceLength = readUnsigned(source, cursor + 4, /* width= */ 8);
      cursor += 12 + priorPathLength + 32 + priorSourceLength;
      entry += 1;
    }

    long pathLength = readUnsigned(source, cursor, /* width= */ 4);
    long sourceLength = readUnsigned(source, cursor + 4, /* width= */ 8);
    long pathStart = cursor + 12;
    long sourceStart = pathStart + pathLength + 32;
    return new ArchiveEntry(pathStart, pathLength, sourceStart, sourceLength);
  }

  /// Validates and decodes `archive` from a bounded canonical input.
  public ArchiveResult inspectArchive(
    borrow byteview source,
    borrow mut bytes digest,
    borrow mut region arena
  ) {
    long fileLength = bufferLength(source);
    if (fileLength < 64) {
      return new ArchiveResult.Error(0);
    }

    long payloadLength = fileLength - 32;
    if (digestMatches(source, 0, payloadLength, payloadLength, digest, arena)) {} else {
      return new ArchiveResult.Error(payloadLength);
    }

    if (magicValid(source)) {} else {
      return new ArchiveResult.Error(0);
    }

    long manifestLength = readUnsigned(source, /* offset= */ 8, /* width= */ 4);
    long entryCount = readUnsigned(source, /* offset= */ 12, /* width= */ 4);
    if (manifestLength < 1) {
      return new ArchiveResult.Error(8);
    }

    if (4096 < manifestLength) {
      return new ArchiveResult.Error(8);
    }

    if (entryCount < 1) {
      return new ArchiveResult.Error(12);
    }

    if (MAX_ENTRIES < entryCount) {
      return new ArchiveResult.Error(12);
    }

    long manifestStart = 16;
    long cursor = manifestStart + manifestLength;
    if (payloadLength < cursor + 12) {
      return new ArchiveResult.Error(cursor);
    }

    if (canonicalManifestEnvelope(source, manifestStart, manifestLength)) {} else {
      return new ArchiveResult.Error(manifestStart);
    }

    words pathStarts = allocate(arena, MAX_ENTRIES);
    words pathLengths = allocate(arena, MAX_ENTRIES);
    long previousPathStart = 0;
    long previousPathLength = 0;
    long entry = 0;
    boolean entriesValid = true;
    while (entry < entryCount) limit MAX_ENTRIES {
      long entryStart = cursor;
      if (payloadLength < entryStart + 12) {
        entriesValid = false;
      }

      if (entriesValid) {
        long pathLength = readUnsigned(source, entryStart, /* width= */ 4);
        long dataLength = readUnsigned(source, entryStart + 4, /* width= */ 8);
        long pathStart = entryStart + 12;
        long entryDigest = pathStart + pathLength;
        long dataStart = entryDigest + 32;
        long entryEnd = dataStart + dataLength;
        if (pathLength < 1) {
          entriesValid = false;
        }

        if (4096 < pathLength) {
          entriesValid = false;
        }

        if (16777216 < dataLength) {
          entriesValid = false;
        }

        if (payloadLength < entryEnd) {
          entriesValid = false;
        }

        if (entriesValid) {
          if (validAsciiPath(source, pathStart, pathLength)) {} else {
            entriesValid = false;
          }
        }

        if (entriesValid) {
          if (0 < entry) {
            if (
              compareAsciiRanges(
                source,
                previousPathStart,
                previousPathLength,
                pathStart,
                pathLength
              ) < 0
            ) {} else {
              entriesValid = false;
            }
          }
        }

        if (entriesValid) {
          if (
            digestMatches(source, dataStart, dataLength, entryDigest, digest, arena)
          ) {} else {
            entriesValid = false;
          }
        }

        if (entriesValid) {
          set(pathStarts, entry, pathStart);
          set(pathLengths, entry, pathLength);
          previousPathStart = pathStart;
          previousPathLength = pathLength;
          cursor = entryEnd;
          entry += 1;
        }
      }

      if (entriesValid == false) {
        entry = entryCount;
      }
    }

    if (entriesValid) {
      entriesValid = cursor == payloadLength;
    }

    if (entriesValid == false) {
      drop(pathLengths);
      drop(pathStarts);
      return new ArchiveResult.Error(cursor);
    }

    bytes manifestBytes = allocateBytes(arena, manifestLength);
    long copyCursor = 0;
    while (copyCursor < manifestLength) limit 4096 {
      setByte(manifestBytes, copyCursor, source[manifestStart + copyCursor]);
      copyCursor += 1;
    }

    utf8 manifest = freezeUtf8(manifestBytes);
    words kinds = allocate(arena, 128);
    words starts = allocate(arena, 128);
    words lengths = allocate(arena, 128);
    words targetRows = allocate(arena, TARGET_ROW_WIDTH);
    words sourceRows = allocate(arena, SOURCE_ROW_WIDTH * MAX_ENTRIES);
    words dependencyRows = allocate(arena, DEPENDENCY_ROW_WIDTH * 2);
    words capabilityRows = allocate(arena, CAPABILITY_ROW_WIDTH * 2);
    long tokenCount = 0;
    boolean valid = true;
    ScanResult scanned = scan(manifest, kinds, starts, lengths);
    match (scanned) {
      case ScanResult.Value(long count) {
        tokenCount = count;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        valid = false;
      }
    }

    long packageLength = 0;
    long targetCount = 0;
    long sourceCount = 0;
    long rootStart = 0;
    long rootLength = 0;
    if (valid) {
      ManifestResult parsed = parseManifest(
        manifest,
        kinds,
        starts,
        lengths,
        tokenCount,
        targetRows,
        sourceRows,
        dependencyRows,
        capabilityRows
      );
      match (parsed) {
        case ManifestResult.Value(ManifestModel model) {
          packageLength = model.name.length;
          targetCount = model.targetCount;
          sourceCount = targetRows[TARGET_SOURCE_COUNT];
          rootStart = targetRows[TARGET_ROOT_START];
          rootLength = targetRows[TARGET_ROOT_LENGTH];
        }
        case ManifestResult.Error(long parseOffset) {
          valid = false;
        }
      }
    }

    if (valid) {
      valid = canonicalPackageManifest(manifest, kinds, starts, lengths, tokenCount);
    }

    if (targetCount == 1) {} else {
      valid = false;
    }

    long expectedEntries = sourceCount;
    if (expectedEntries == 0) {
      expectedEntries = 1;
    }

    if (expectedEntries == entryCount) {} else {
      valid = false;
    }

    entry = 0;
    while (entry < entryCount) limit MAX_ENTRIES {
      if (valid) {
        long expectedStart = rootStart;
        long expectedLength = rootLength;
        if (0 < sourceCount) {
          expectedStart = sourceRows[entry * 2];
          expectedLength = sourceRows[entry * 2 + 1];
        }

        valid = pathMatchesManifest(
          source,
          pathStarts[entry],
          pathLengths[entry],
          manifest,
          expectedStart,
          expectedLength
        );
      }

      entry += 1;
    }

    boolean pathsValid = valid;
    drop(capabilityRows);
    drop(dependencyRows);
    drop(sourceRows);
    drop(targetRows);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(manifest);
    drop(pathLengths);
    drop(pathStarts);
    if (pathsValid) {
      ArchiveModel archive = new ArchiveModel(
        manifestLength,
        entryCount,
        packageLength,
        targetCount
      );
      return new ArchiveResult.Value(archive);
    }

    return new ArchiveResult.Error(manifestStart);
  }
}
