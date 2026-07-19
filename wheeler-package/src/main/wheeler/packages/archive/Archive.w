//! Validates bounded canonical package archive structure.

module wheeler.packages.archive;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.lexer.scanner;
import wheeler.packages.line_emitter;
import wheeler.packages.manifest;

classical class Archive {
  /// Defines immutable `ArchiveModel` values for this module.
  public record ArchiveModel(
    long manifestLength,
    long entryCount,
    long pathLength,
    long dataLength,
    long secondPathLength,
    long secondDataLength,
    long packageLength,
    long targetCount
  ) {}

  /// Defines the closed `ArchiveResult` cases exported by this module.
  public variant ArchiveResult {
    case Value(ArchiveModel archive);
    case Error(long offset);
  }

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

    long manifestLength = readUnsigned(source, 8, 4);
    long entryCount = readUnsigned(source, 12, 4);
    if (manifestLength < 1) {
      return new ArchiveResult.Error(8);
    }

    if (4096 < manifestLength) {
      return new ArchiveResult.Error(8);
    }

    if (entryCount < 1) {
      return new ArchiveResult.Error(12);
    }

    if (2 < entryCount) {
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

    long pathLength = readUnsigned(source, cursor, 4);
    cursor += 4;
    long dataLength = readUnsigned(source, cursor, 8);
    cursor += 8;
    if (pathLength < 1) {
      return new ArchiveResult.Error(cursor);
    }

    if (4096 < pathLength) {
      return new ArchiveResult.Error(cursor);
    }

    if (16777216 < dataLength) {
      return new ArchiveResult.Error(cursor);
    }

    long pathStart = cursor;
    long entryDigest = pathStart + pathLength;
    long dataStart = entryDigest + 32;
    long firstEnd = dataStart + dataLength;
    if (firstEnd < payloadLength) {} else {
      if (entryCount == 1) {
        if (firstEnd == payloadLength) {} else {
          return new ArchiveResult.Error(cursor);
        }
      } else {
        return new ArchiveResult.Error(cursor);
      }
    }

    if (validAsciiPath(source, pathStart, pathLength)) {} else {
      return new ArchiveResult.Error(pathStart);
    }

    if (digestMatches(source, dataStart, dataLength, entryDigest, digest, arena)) {} else {
      return new ArchiveResult.Error(entryDigest);
    }

    long secondPathStart = 0;
    long secondPathLength = 0;
    long secondDataLength = 0;
    if (entryCount == 2) {
      cursor = firstEnd;
      if (payloadLength < cursor + 12) {
        return new ArchiveResult.Error(cursor);
      }

      secondPathLength = readUnsigned(source, cursor, 4);
      cursor += 4;
      secondDataLength = readUnsigned(source, cursor, 8);
      cursor += 8;
      if (secondPathLength < 1) {
        return new ArchiveResult.Error(cursor);
      }

      if (4096 < secondPathLength) {
        return new ArchiveResult.Error(cursor);
      }

      if (16777216 < secondDataLength) {
        return new ArchiveResult.Error(cursor);
      }

      secondPathStart = cursor;
      long secondDigest = secondPathStart + secondPathLength;
      long secondData = secondDigest + 32;
      if (secondData + secondDataLength == payloadLength) {} else {
        return new ArchiveResult.Error(cursor);
      }

      if (validAsciiPath(source, secondPathStart, secondPathLength)) {} else {
        return new ArchiveResult.Error(secondPathStart);
      }

      if (
        compareAsciiRanges(source, pathStart, pathLength, secondPathStart, secondPathLength) < 0
      ) {} else {
        return new ArchiveResult.Error(secondPathStart);
      }

      if (
        digestMatches(source, secondData, secondDataLength, secondDigest, digest, arena)
      ) {} else {
        return new ArchiveResult.Error(secondDigest);
      }
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
    words sourceRows = allocate(arena, SOURCE_ROW_WIDTH * 2);
    words dependencyRows = allocate(arena, DEPENDENCY_ROW_WIDTH * 2);
    words capabilityRows = allocate(arena, CAPABILITY_ROW_WIDTH * 2);
    bytes canonical = allocateBytes(arena, manifestLength);
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
    long firstSourceStart = 0;
    long firstSourceLength = 0;
    long secondSourceStart = 0;
    long secondSourceLength = 0;
    long sourceCount = 0;
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
          if (sourceCount == 0) {
            firstSourceStart = targetRows[TARGET_ROOT_START];
            firstSourceLength = targetRows[TARGET_ROOT_LENGTH];
          } else {
            firstSourceStart = sourceRows[0];
            firstSourceLength = sourceRows[1];
            secondSourceStart = sourceRows[2];
            secondSourceLength = sourceRows[3];
          }
        }
        case ManifestResult.Error(long parseOffset) {
          valid = false;
        }
      }
    }

    long emittedLength = 0;
    if (valid) {
      emittedLength = emitCanonicalLines(manifest, starts, lengths, tokenCount, canonical);
      if (emittedLength == manifestLength) {} else {
        valid = false;
      }
    }

    long compareCursor = 0;
    while (compareCursor < manifestLength) limit 4096 {
      if (valid) {
        if (canonical[compareCursor] == source[manifestStart + compareCursor]) {} else {
          valid = false;
        }
      }

      compareCursor += 1;
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

    if (valid) {
      valid = pathMatchesManifest(
        source,
        pathStart,
        pathLength,
        manifest,
        firstSourceStart,
        firstSourceLength
      );
    }

    if (entryCount == 2) {
      if (valid) {
        valid = pathMatchesManifest(
          source,
          secondPathStart,
          secondPathLength,
          manifest,
          secondSourceStart,
          secondSourceLength
        );
      }
    }

    drop(canonical);
    drop(capabilityRows);
    drop(dependencyRows);
    drop(sourceRows);
    drop(targetRows);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(manifest);
    if (valid) {
      ArchiveModel archive = new ArchiveModel(
        manifestLength,
        entryCount,
        pathLength,
        dataLength,
        secondPathLength,
        secondDataLength,
        packageLength,
        targetCount
      );
      return new ArchiveResult.Value(archive);
    }

    return new ArchiveResult.Error(manifestStart);
  }
}
