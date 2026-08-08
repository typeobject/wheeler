//! Verifies and identifies one bounded canonical bootstrap artifact-set manifest.

module wheeler.conformance.bootstrap.artifact_set_identity;

import wheeler.compiler.closure.manifest_syntax;
import wheeler.crypto.sha256;

classical class NativeArtifactSetIdentity {
  state long artifactCount = 0;
  state long canonicalLength = 0;
  state long validationPhase = 0;
  state long published = 0;

  private boolean pathByte(long scalar) {
    boolean valid = 47 < scalar;
    if (57 < scalar) {
      valid = false;
    }

    if (64 < scalar) {
      valid = scalar < 91;
    }

    if (96 < scalar) {
      valid = scalar < 123;
    }

    if (scalar == 45) {
      valid = true;
    }

    if (scalar == 46) {
      valid = true;
    }

    if (scalar == 47) {
      valid = true;
    }

    if (scalar == 95) {
      valid = true;
    }

    return valid;
  }

  private boolean segmentValid(borrow byteview source, long start, long length) {
    if (length == 0) {
      return false;
    }

    if (length == 1) {
      if (source[start] == 46) {
        return false;
      }

      return true;
    }

    if (length == 2) {
      if (source[start] == 46) {
        if (source[start + 1] == 46) {
          return false;
        }
      }
    }

    return true;
  }

  private boolean validPath(borrow byteview source, long start, long length) {
    if (length < 5) {
      return false;
    }

    if (256 < length) {
      return false;
    }

    if (source[start + length - 4] == 46) {} else {
      return false;
    }

    if (source[start + length - 3] == 119) {} else {
      return false;
    }

    if (source[start + length - 2] == 98) {} else {
      return false;
    }

    if (source[start + length - 1] == 99) {} else {
      return false;
    }

    long segmentStart = start;
    long cursor = start;
    long end = start + length;
    while (cursor < end) limit 256 {
      long scalar = source[cursor];
      if (pathByte(scalar) == false) {
        return false;
      }

      if (scalar == 47) {
        if (segmentValid(source, segmentStart, cursor - segmentStart) == false) {
          return false;
        }

        segmentStart = cursor + 1;
      }

      cursor += 1;
    }

    return segmentValid(source, segmentStart, end - segmentStart);
  }

  private long comparePaths(
    borrow byteview source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long length = leftLength;
    if (rightLength < length) {
      length = rightLength;
    }

    long index = 0;
    while (index < length) limit 256 {
      long difference = source[leftStart + index] - source[rightStart + index];
      if (difference == 0) {
        index += 1;
      } else {
        return difference;
      }
    }

    return leftLength - rightLength;
  }

  private boolean lowercaseHex(long scalar) {
    boolean valid = 47 < scalar;
    if (57 < scalar) {
      valid = false;
    }

    if (96 < scalar) {
      valid = scalar < 103;
    }

    return valid;
  }

  private long hexValue(long scalar) {
    if (scalar < 58) {
      return scalar - 48;
    }

    return scalar - 87;
  }

  private long writeField(
    borrow mut bytes canonical,
    long cursor,
    borrow byteview source,
    long start,
    long length
  ) {
    setByte(canonical, cursor, length & 255);
    setByte(canonical, cursor + 1, (length / 256) & 255);
    setByte(canonical, cursor + 2, (length / 65536) & 255);
    setByte(canonical, cursor + 3, (length / 16777216) & 255);
    cursor += 4;
    long index = 0;
    while (index < length) limit 256 {
      setByte(canonical, cursor + index, source[start + index]);
      index += 1;
    }

    return cursor + length;
  }

  private long writeProfileField(borrow mut bytes canonical) {
    setByte(canonical, 0, 22);
    setByte(canonical, 1, 0);
    setByte(canonical, 2, 0);
    setByte(canonical, 3, 0);
    writeAscii(canonical, 4, "wheeler.artifact-set/1");
    return 26;
  }

  private boolean digestMatches(
    borrow byteview source,
    long identityStart,
    borrow mut bytes digest
  ) {
    long index = 0;
    while (index < 32) limit 32 {
      long high = source[identityStart + index * 2];
      long low = source[identityStart + index * 2 + 1];
      if (lowercaseHex(high) == false) {
        return false;
      }

      if (lowercaseHex(low) == false) {
        return false;
      }

      if (digest[index] == hexValue(high) * 16 + hexValue(low)) {} else {
        return false;
      }

      index += 1;
    }

    return true;
  }

  private long writeArtifactsHeader(borrow mut bytes expected) {
    setByte(expected, 0, 123);
    setByte(expected, 1, 34);
    writeAscii(expected, 2, "artifacts");
    long cursor = 11;
    setByte(expected, cursor, 34);
    setByte(expected, cursor + 1, 58);
    setByte(expected, cursor + 2, 91);
    return cursor + 3;
  }

  private long writeBytesPrefix(borrow mut bytes expected) {
    setByte(expected, 0, 123);
    setByte(expected, 1, 34);
    writeAscii(expected, 2, "bytes");
    long cursor = 7;
    setByte(expected, cursor, 34);
    setByte(expected, cursor + 1, 58);
    return cursor + 2;
  }

  private long writeNamedStringPrefix(borrow mut bytes expected, long leading, boolean sha) {
    setByte(expected, 0, leading);
    setByte(expected, 1, 34);
    long cursor = 6;
    if (sha) {
      writeAscii(expected, 2, "sha256");
      cursor = 8;
    } else {
      writeAscii(expected, 2, "path");
    }

    setByte(expected, cursor, 34);
    setByte(expected, cursor + 1, 58);
    setByte(expected, cursor + 2, 34);
    return cursor + 3;
  }

  private long writeIdentityPrefix(borrow mut bytes expected) {
    setByte(expected, 0, 93);
    setByte(expected, 1, 44);
    setByte(expected, 2, 34);
    writeAscii(expected, 3, "identity");
    long cursor = 11;
    setByte(expected, cursor, 34);
    setByte(expected, cursor + 1, 58);
    setByte(expected, cursor + 2, 34);
    return cursor + 3;
  }

  private long writeProfileSuffix(borrow mut bytes expected) {
    setByte(expected, 0, 34);
    setByte(expected, 1, 44);
    setByte(expected, 2, 34);
    writeAscii(expected, 3, "profile");
    long cursor = 10;
    setByte(expected, cursor, 34);
    setByte(expected, cursor + 1, 58);
    setByte(expected, cursor + 2, 34);
    writeAscii(expected, 13, "wheeler.artifact-set/1");
    cursor = 35;
    setByte(expected, cursor, 34);
    setByte(expected, cursor + 1, 125);
    setByte(expected, cursor + 2, 10);
    return cursor + 3;
  }

  /// Publishes the accepted set identity only after complete canonical validation.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < 4097, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(5600, 8);
    bytes canonical = allocateBytes(arena, 4096);
    bytes expected = allocateBytes(arena, 64);
    bytes digest = allocateBytes(arena, 32);
    long encoded = writeProfileField(canonical);
    long expectedLength = writeArtifactsHeader(expected);
    long cursor = consumeMetadata(source, 0, expected, expectedLength);
    validationPhase = 1;
    long previousPathStart = 0;
    long previousPathLength = 0;
    long count = 0;
    boolean more = true;
    while (more) limit 8 {
      expectedLength = writeBytesPrefix(expected);
      cursor = consumeMetadata(source, cursor, expected, expectedLength);
      long bytesStart = cursor;
      long byteLength = 0;
      long bytesValue = 0;
      while (cursor < bufferLength(source)) limit 8 {
        long digit = source[cursor];
        if (47 < digit) {
          if (digit < 58) {
            bytesValue = bytesValue * 10 + digit - 48;
            byteLength += 1;
            cursor += 1;
          } else {
            break;
          }
        } else {
          break;
        }
      }

      requireMetadata(0 < byteLength, source);
      if (source[bytesStart] == 48) {
        requireMetadata(false, source);
      }

      requireMetadata(0 < bytesValue, source);
      requireMetadata(bytesValue < 16777217, source);
      validationPhase = 2;
      expectedLength = writeNamedStringPrefix(expected, 44, false);
      cursor = consumeMetadata(source, cursor, expected, expectedLength);
      long pathStart = cursor;
      while (cursor < bufferLength(source)) limit 256 {
        if (source[cursor] == 34) {
          break;
        }

        cursor += 1;
      }

      long pathLength = cursor - pathStart;
      validationPhase = 3;
      requireMetadata(validPath(source, pathStart, pathLength), source);
      if (0 < count) {
        requireMetadata(
          comparePaths(source, previousPathStart, previousPathLength, pathStart, pathLength) < 0,
          source
        );
      }

      previousPathStart = pathStart;
      previousPathLength = pathLength;
      requireMetadata(source[cursor] == 34, source);
      cursor += 1;
      validationPhase = 4;
      expectedLength = writeNamedStringPrefix(expected, 44, true);
      cursor = consumeMetadata(source, cursor, expected, expectedLength);
      long shaStart = cursor;
      long shaIndex = 0;
      while (shaIndex < 64) limit 64 {
        requireMetadata(lowercaseHex(source[cursor + shaIndex]), source);
        shaIndex += 1;
      }

      cursor += 64;
      validationPhase = 5;
      setByte(expected, 0, 34);
      setByte(expected, 1, 125);
      cursor = consumeMetadata(source, cursor, expected, 2);
      encoded = writeField(canonical, encoded, source, pathStart, pathLength);
      encoded = writeField(canonical, encoded, source, shaStart, 64);
      encoded = writeField(canonical, encoded, source, bytesStart, byteLength);
      count += 1;
      validationPhase = 6;
      if (source[cursor] == 44) {
        cursor += 1;
      } else {
        more = false;
      }
    }

    requireMetadata(0 < count, source);
    validationPhase = 7;
    expectedLength = writeIdentityPrefix(expected);
    cursor = consumeMetadata(source, cursor, expected, expectedLength);
    long identityStart = cursor;
    cursor += 64;
    validationPhase = 8;
    expectedLength = writeProfileSuffix(expected);
    cursor = consumeMetadata(source, cursor, expected, expectedLength);
    requireMetadata(cursor == bufferLength(source), source);
    validationPhase = 9;
    hashSha256Range(canonical, 0, encoded, digest, arena);
    requireMetadata(digestMatches(source, identityStart, digest), source);
    long outputIndex = 0;
    while (outputIndex < 32) limit 32 {
      setByte(identity, outputIndex, digest[outputIndex]);
      outputIndex += 1;
    }

    artifactCount = count;
    canonicalLength = encoded;
    published = 1;
    setOutputLength(identity, 32);
    drop(digest);
    drop(expected);
    drop(canonical);
    drop(arena);
  }
}
