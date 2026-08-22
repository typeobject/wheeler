//! Validates package and selected-target fields in canonical runner manifests.

module wheeler.runtime.testing.runners.test_manifest;

classical class TestManifest {
  private const long MAX_MANIFEST_BYTES = 4096;

  private long lineEnd(borrow byteview input, long cursor, long end) {
    long scan = cursor;
    while (scan < end) limit MAX_MANIFEST_BYTES {
      if (input[scan] == 10) {
        return scan;
      }

      assert(input[scan] != 13);
      scan += 1;
    }

    return -1;
  }

  private long rangeHash(borrow byteview input, long start, long length) {
    long hash = 0;
    long offset = 0;
    while (offset < length) limit MAX_MANIFEST_BYTES {
      hash = (hash * 131 + input[start + offset]) % 4294967296;
      offset += 1;
    }

    return hash;
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

  private boolean sameValue(borrow byteview input, long inputStart, borrow byteview value) {
    long offset = 0;
    while (offset < bufferLength(value)) limit 255 {
      if (input[inputStart + offset] != value[offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long readUnsigned32BigEndian(borrow byteview input, long offset) {
    return input[offset] * 16777216 + input[offset + 1] * 65536 + input[offset + 2] * 256
      + input[offset + 3];
  }

  private boolean sameRange(borrow byteview input, long leftStart, long rightStart, long length) {
    long offset = 0;
    while (offset < length) limit 255 {
      if (input[leftStart + offset] != input[rightStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private boolean rootModule(
    borrow byteview input,
    long sourceStart,
    long sourceLength,
    long moduleStart,
    long moduleLength
  ) {
    if (sourceLength < moduleLength + 9) {
      return false;
    }

    if (input[sourceStart] != 109) {
      return false;
    }

    if (input[sourceStart + 1] != 111) {
      return false;
    }

    if (input[sourceStart + 2] != 100) {
      return false;
    }

    if (input[sourceStart + 3] != 117) {
      return false;
    }

    if (input[sourceStart + 4] != 108) {
      return false;
    }

    if (input[sourceStart + 5] != 101) {
      return false;
    }

    if (input[sourceStart + 6] != 32) {
      return false;
    }

    if (sameRange(input, sourceStart + 7, moduleStart, moduleLength) == false) {
      return false;
    }

    if (input[sourceStart + 7 + moduleLength] != 59) {
      return false;
    }

    return input[sourceStart + 8 + moduleLength] == 10;
  }

  private boolean sourceLine(
    borrow byteview input,
    long start,
    long end,
    long sourcePathStart,
    long sourcePathLength
  ) {
    if (end - start != sourcePathLength + 10) {
      return false;
    }

    if (rangeHash(input, start, /* length= */ 9) != 1271526807) {
      return false;
    }

    if (sameRange(input, start + 9, sourcePathStart, sourcePathLength) == false) {
      return false;
    }

    return input[end - 1] == 34;
  }

  private boolean fieldLine(
    borrow byteview input,
    long start,
    long end,
    long prefixLength,
    long prefixHash,
    borrow byteview value
  ) {
    if (end - start != prefixLength + bufferLength(value) + 1) {
      return false;
    }

    if (rangeHash(input, start, prefixLength) != prefixHash) {
      return false;
    }

    if (sameValue(input, start + prefixLength, value) == false) {
      return false;
    }

    return input[end - 1] == 34;
  }

  /// Checks canonical header fields and one test-selected target before execution.
  public boolean validTestManifest(
    borrow byteview input,
    long start,
    long length,
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    long sourcePlanStart,
    long sourcePlanLength
  ) {
    assert(0 < length);
    assert(length < MAX_MANIFEST_BYTES + 1);
    long end = start + length;
    assert(end < bufferLength(input) + 1);
    assert(input[end - 1] == 10);

    long cursor = start;
    long found = lineEnd(input, cursor, end);
    if (
      exactLine(input, cursor, found, /* length= */ 9, /* hash= */ 2571233518) == false
    ) {
      return false;
    }

    cursor = found + 1;
    found = lineEnd(input, cursor, end);
    if (
      exactLine(input, cursor, found, /* length= */ 8, /* hash= */ 1538262944) == false
    ) {
      return false;
    }

    cursor = found + 1;
    found = lineEnd(input, cursor, end);
    if (
      fieldLine(
        input,
        cursor,
        found,
        /* prefixLength= */ 9,
        /* prefixHash= */ 2276377217,
        packageName
      ) == false
    ) {
      return false;
    }

    cursor = found + 1;
    found = lineEnd(input, cursor, end);
    if (
      fieldLine(
        input,
        cursor,
        found,
        /* prefixLength= */ 12,
        /* prefixHash= */ 1752260728,
        packageVersion
      ) == false
    ) {
      return false;
    }

    cursor = found + 1;
    found = lineEnd(input, cursor, end);
    if (
      exactLine(input, cursor, found, /* length= */ 24, /* hash= */ 1491761755) == false
    ) {
      return false;
    }

    cursor = found + 1;
    found = lineEnd(input, cursor, end);
    if (
      exactLine(input, cursor, found, /* length= */ 8, /* hash= */ 2958901072) == false
    ) {
      return false;
    }

    cursor = found + 1;

    long sourceCount = readUnsigned32BigEndian(input, sourcePlanStart);
    long sourceCursor = sourcePlanStart + 4;
    long selectedSources = 0;
    boolean runnableKind = false;
    boolean candidate = false;
    boolean sourceSection = false;
    boolean rootSelected = false;
    boolean selectedRootPath = false;
    boolean selected = false;
    boolean dependencies = false;
    long rootStart = 0;
    long rootLength = 0;
    long rootSourceStart = 0;
    long rootSourceLength = 0;
    long moduleStart = 0;
    long moduleLength = 0;
    while (cursor < end) limit MAX_MANIFEST_BYTES {
      found = lineEnd(input, cursor, end);
      long lineLength = found - cursor;
      if (12 < lineLength) {
        if (rangeHash(input, cursor, /* length= */ 13) == 344468657) {
          dependencies = true;
          cursor = found + 1;
          break;
        }
      }

      if (9 < lineLength) {
        if (rangeHash(input, cursor, /* length= */ 10) == 2457211845) {
          runnableKind = exactLine(
            input,
            cursor,
            found,
            /* length= */ 22,
            /* hash= */ 2378483464
          );
          candidate = false;
          sourceSection = false;
          rootSelected = false;
          rootStart = 0;
          rootLength = 0;
          rootSourceStart = 0;
          rootSourceLength = 0;
          moduleStart = 0;
          moduleLength = 0;
          sourceCursor = sourcePlanStart + 4;
          selectedSources = 0;
        }
      }

      if (
        fieldLine(
          input,
          cursor,
          found,
          /* prefixLength= */ 11,
          /* prefixHash= */ 3709182977,
          targetName
        )
      ) {
        candidate = runnableKind;
        sourceCursor = sourcePlanStart + 4;
        selectedSources = 0;
      }

      if (candidate) {
        if (11 < lineLength) {
          if (rangeHash(input, cursor, /* length= */ 11) == 2520394854) {
            if (input[found - 1] != 34) {
              return false;
            }

            rootStart = cursor + 11;
            rootLength = lineLength - 12;
            if (rootLength == 0) {
              return false;
            }
          }
        }

        if (13 < lineLength) {
          if (rangeHash(input, cursor, /* length= */ 13) == 3005111940) {
            if (input[found - 1] != 34) {
              return false;
            }

            moduleStart = cursor + 13;
            moduleLength = lineLength - 14;
            if (moduleLength == 0) {
              return false;
            }
          }
        }

        if (exactLine(input, cursor, found, /* length= */ 12, /* hash= */ 515471674)) {
          sourceSection = true;
        } else {
          if (sourceSection) {
            if (selectedSources < sourceCount) {
              long sourcePathLength = readUnsigned32BigEndian(input, sourceCursor);
              long sourcePathStart = sourceCursor + 4;
              if (
                sourceLine(input, cursor, found, sourcePathStart, sourcePathLength) == false
              ) {
                return false;
              }

              selectedRootPath = false;
              if (sourcePathLength == rootLength) {
                if (sameRange(input, sourcePathStart, rootStart, rootLength)) {
                  rootSelected = true;
                  selectedRootPath = true;
                }
              }

              sourceCursor += 4 + sourcePathLength;
              long sourceLength = readUnsigned32BigEndian(input, sourceCursor);
              sourceCursor += 4;
              if (selectedRootPath) {
                rootSourceStart = sourceCursor;
                rootSourceLength = sourceLength;
              }

              sourceCursor += sourceLength;
              selectedSources += 1;
            } else {
              if (
                exactLine(input, cursor, found, /* length= */ 14, /* hash= */ 4023520342)
              ) {
                if (rootSelected) {
                  if (sourceCursor == sourcePlanStart + sourcePlanLength) {
                    selected = rootModule(
                      input,
                      rootSourceStart,
                      rootSourceLength,
                      moduleStart,
                      moduleLength
                    );
                  }
                }

                sourceSection = false;
              } else {
                return false;
              }
            }
          }
        }
      }

      cursor = found + 1;
    }

    if (dependencies) {
      return selected;
    }

    return false;
  }
}
