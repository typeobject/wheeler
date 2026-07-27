//! Verifies and identifies a bounded canonical bootstrap module closure.

module examples.bootstrap.modules_identity;

import examples.bootstrap.syntax;
import wheeler.crypto.content_identity;

classical class NativeBootstrapModulesIdentity {
  state long moduleCount = 0;
  state long externalCount = 0;
  state long importCount = 0;
  state long published = 0;

  private boolean moduleByte(long scalar, boolean first) {
    boolean valid = scalar == 95;
    if (64 < scalar) {
      valid = scalar < 91;
    }

    if (96 < scalar) {
      valid = scalar < 123;
    }

    if (first == false) {
      if (47 < scalar) {
        if (scalar < 58) {
          valid = true;
        }
      }
    }

    return valid;
  }

  private long consumeModuleName(borrow byteview source, long cursor) {
    long start = cursor;
    boolean first = true;
    while (cursor < bufferLength(source)) limit 128 {
      long scalar = source[cursor];
      if (scalar == 34) {
        break;
      }

      if (scalar == 46) {
        requireMetadata(first == false, source);
        first = true;
      } else {
        requireMetadata(moduleByte(scalar, first), source);
        first = false;
      }

      cursor += 1;
    }

    requireMetadata(start < cursor, source);
    requireMetadata(first == false, source);
    requireMetadata(cursor - start < 129, source);
    requireMetadata(source[cursor] == 34, source);
    return cursor;
  }

  private boolean sameText(
    borrow byteview source,
    long left,
    long leftLength,
    long right,
    long rightLength
  ) {
    boolean same = leftLength == rightLength;
    long index = 0;
    while (index < leftLength) limit 128 {
      if ((source[left + index] == source[right + index]) == false) {
        same = false;
      }

      index += 1;
    }

    return same;
  }

  private boolean orderedAfter(
    borrow byteview source,
    long previous,
    long previousLength,
    long current,
    long currentLength
  ) {
    long common = previousLength;
    if (currentLength < common) {
      common = currentLength;
    }

    long index = 0;
    long relation = 0;
    while (index < common) limit 128 {
      if (relation == 0) {
        if (source[previous + index] < source[current + index]) {
          relation = 1;
        }

        if (source[current + index] < source[previous + index]) {
          relation = -1;
        }
      }

      index += 1;
    }

    if (relation == 0) {
      return previousLength < currentLength;
    }

    return relation == 1;
  }

  private long consumeSourcePath(borrow byteview source, long cursor) {
    long start = cursor;
    boolean separator = true;
    while (cursor < bufferLength(source)) limit 256 {
      long scalar = source[cursor];
      if (scalar == 34) {
        break;
      }

      boolean ordinary = scalar == 45;
      if (scalar == 95) {
        ordinary = true;
      }

      if (47 < scalar) {
        if (scalar < 58) {
          ordinary = true;
        }
      }

      if (64 < scalar) {
        if (scalar < 91) {
          ordinary = true;
        }
      }

      if (96 < scalar) {
        if (scalar < 123) {
          ordinary = true;
        }
      }

      boolean punctuation = false;
      if (scalar == 46) {
        requireMetadata(separator == false, source);
        separator = true;
        punctuation = true;
      }

      if (scalar == 47) {
        requireMetadata(separator == false, source);
        separator = true;
        punctuation = true;
      }

      if (punctuation == false) {
        requireMetadata(ordinary, source);
        separator = false;
      }

      cursor += 1;
    }

    requireMetadata(start + 2 < cursor, source);
    requireMetadata(separator == false, source);
    requireMetadata(source[cursor - 2] == 46, source);
    requireMetadata(source[cursor - 1] == 119, source);
    requireMetadata(source[cursor] == 34, source);
    return cursor;
  }

  private boolean listed(
    borrow byteview source,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long candidate,
    long candidateLength
  ) {
    boolean found = false;
    long index = 0;
    while (index < count) limit 4 {
      if (
        sameText(source, starts[index], lengths[index], candidate, candidateLength)
      ) {
        found = true;
      }

      index += 1;
    }

    return found;
  }

  /// Publishes SHA-256 for one canonical rooted module and up to four externals.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < 2049, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(1800, 12);
    bytes expected = allocateBytes(arena, 256);
    words externalStarts = allocate(arena, 4);
    words externalLengths = allocate(arena, 4);
    words importedStarts = allocate(arena, 4);
    words importedLengths = allocate(arena, 4);

    writeAscii(expected, 0, "schema: 1");
    setByte(expected, 9, 10);
    writeAscii(expected, 10, "profile: ");
    setByte(expected, 19, 34);
    long cursor = consumeMetadata(source, 0, expected, 20);
    long profileStart = cursor;
    while (cursor < bufferLength(source)) limit 128 {
      if (source[cursor] == 34) {
        break;
      }

      requireMetadata(profileByte(source[cursor], cursor == profileStart), source);
      cursor += 1;
    }

    requireMetadata(profileStart < cursor, source);
    requireMetadata(cursor - profileStart < 129, source);

    setByte(expected, 0, 34);
    setByte(expected, 1, 10);
    writeAscii(expected, 2, "root: ");
    setByte(expected, 8, 34);
    cursor = consumeMetadata(source, cursor, expected, 9);
    long rootStart = cursor;
    cursor = consumeModuleName(source, cursor);
    long rootLength = cursor - rootStart;
    setByte(expected, 0, 34);
    setByte(expected, 1, 10);
    writeAscii(expected, 2, "externals:");
    cursor = consumeMetadata(source, cursor, expected, 12);

    long parsedExternals = 0;
    if (source[cursor] == 32) {
      writeAscii(expected, 0, " []");
      setByte(expected, 3, 10);
      cursor = consumeMetadata(source, cursor, expected, 4);
    } else {
      setByte(expected, 0, 10);
      writeAscii(expected, 1, "  - ");
      setByte(expected, 5, 34);
      cursor = consumeMetadata(source, cursor, expected, 6);
      boolean moreExternals = true;
      while (moreExternals) limit 4 {
        requireMetadata(parsedExternals < 4, source);
        long nameStart = cursor;
        cursor = consumeModuleName(source, cursor);
        long nameLength = cursor - nameStart;
        requireMetadata(
          sameText(source, rootStart, rootLength, nameStart, nameLength) == false,
          source
        );
        if (0 < parsedExternals) {
          requireMetadata(
            orderedAfter(
              source,
              externalStarts[parsedExternals - 1],
              externalLengths[parsedExternals - 1],
              nameStart,
              nameLength
            ),
            source
          );
        }

        set(externalStarts, parsedExternals, nameStart);
        set(externalLengths, parsedExternals, nameLength);
        parsedExternals += 1;
        setByte(expected, 0, 34);
        setByte(expected, 1, 10);
        cursor = consumeMetadata(source, cursor, expected, 2);
        moreExternals = source[cursor] == 32;
        if (moreExternals) {
          writeAscii(expected, 0, "  - ");
          setByte(expected, 4, 34);
          cursor = consumeMetadata(source, cursor, expected, 5);
        }
      }
    }

    writeAscii(expected, 0, "modules:");
    setByte(expected, 8, 10);
    writeAscii(expected, 9, "  - name: ");
    setByte(expected, 19, 34);
    cursor = consumeMetadata(source, cursor, expected, 20);
    long moduleStart = cursor;
    cursor = consumeModuleName(source, cursor);
    long moduleLength = cursor - moduleStart;
    requireMetadata(
      sameText(source, rootStart, rootLength, moduleStart, moduleLength),
      source
    );

    setByte(expected, 0, 34);
    setByte(expected, 1, 10);
    writeAscii(expected, 2, "    source: ");
    setByte(expected, 14, 34);
    cursor = consumeMetadata(source, cursor, expected, 15);
    cursor = consumeSourcePath(source, cursor);
    setByte(expected, 0, 34);
    setByte(expected, 1, 10);
    writeAscii(expected, 2, "    identity: ");
    cursor = consumeMetadata(source, cursor, expected, 16);
    cursor = consumeQuotedIdentity(source, cursor, expected);

    setByte(expected, 0, 10);
    writeAscii(expected, 1, "    imports:");
    cursor = consumeMetadata(source, cursor, expected, 13);
    long parsedImports = 0;
    if (source[cursor] == 32) {
      writeAscii(expected, 0, " []");
      setByte(expected, 3, 10);
      cursor = consumeMetadata(source, cursor, expected, 4);
    } else {
      setByte(expected, 0, 10);
      writeAscii(expected, 1, "      - ");
      setByte(expected, 9, 34);
      cursor = consumeMetadata(source, cursor, expected, 10);
      boolean moreImports = true;
      while (moreImports) limit 4 {
        requireMetadata(parsedImports < 4, source);
        long importStart = cursor;
        cursor = consumeModuleName(source, cursor);
        long importLength = cursor - importStart;
        requireMetadata(
          listed(
            source,
            externalStarts,
            externalLengths,
            parsedExternals,
            importStart,
            importLength
          ),
          source
        );
        if (0 < parsedImports) {
          requireMetadata(
            orderedAfter(
              source,
              importedStarts[parsedImports - 1],
              importedLengths[parsedImports - 1],
              importStart,
              importLength
            ),
            source
          );
        }

        set(importedStarts, parsedImports, importStart);
        set(importedLengths, parsedImports, importLength);
        parsedImports += 1;
        setByte(expected, 0, 34);
        setByte(expected, 1, 10);
        cursor = consumeMetadata(source, cursor, expected, 2);
        moreImports = cursor < bufferLength(source);
        if (moreImports) {
          writeAscii(expected, 0, "      - ");
          setByte(expected, 8, 34);
          cursor = consumeMetadata(source, cursor, expected, 9);
        }
      }
    }

    requireMetadata(cursor == bufferLength(source), source);
    publishSha256(source, identity, arena);
    moduleCount = 1;
    externalCount = parsedExternals;
    importCount = parsedImports;
    published = 1;
    setOutputLength(identity, 32);
    drop(importedLengths);
    drop(importedStarts);
    drop(externalLengths);
    drop(externalStarts);
    drop(expected);
    drop(arena);
  }
}
