//! Validates package and selected-target fields in canonical runner manifests.

module wheeler.runtime.testing.runners.test_manifest;

import wheeler.runtime.testing.runners.test_source_modules;

classical class TestManifest {
  private const long MAX_MANIFEST_BYTES = 12288;
  private const long MAX_SOURCES = 64;

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

  private boolean runnableKindLine(borrow byteview input, long start, long end) {
    if (exactLine(input, start, end, /* length= */ 22, /* hash= */ 2378483464)) {
      return true;
    }

    return exactLine(input, start, end, /* length= */ 16, /* hash= */ 1372494201);
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

  private boolean dependencyPath(borrow byteview input, long pathStart, long pathLength) {
    if (pathLength < 14) {
      return false;
    }

    return rangeHash(input, pathStart, /* length= */ 13) == 344468646;
  }

  private long externalSourceCount(borrow byteview input, long sourcePlanStart, long sourceCount) {
    long count = 0;
    long cursor = sourcePlanStart + 4;
    long source = 0;
    while (source < sourceCount) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(input, cursor);
      long pathStart = cursor + 4;
      if (dependencyPath(input, pathStart, pathLength)) {
        count += 1;
      }

      cursor = pathStart + pathLength;
      long sourceLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + sourceLength;
      source += 1;
    }

    return count;
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

  /// Finds the root source ordinal after complete manifest and plan validation.
  public long validatedRootSourceOrdinal(
    borrow byteview input,
    long start,
    long length,
    borrow byteview targetName,
    long sourcePlanStart
  ) {
    long end = start + length;
    long cursor = start;
    boolean runnableKind = false;
    boolean candidate = false;
    while (cursor < end) limit MAX_MANIFEST_BYTES {
      long found = lineEnd(input, cursor, end);
      long lineLength = found - cursor;
      if (9 < lineLength) {
        if (rangeHash(input, cursor, /* length= */ 10) == 2457211845) {
          runnableKind = runnableKindLine(input, cursor, found);
          candidate = false;
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
      }

      if (candidate) {
        if (11 < lineLength) {
          if (rangeHash(input, cursor, /* length= */ 11) == 2520394854) {
            long rootStart = cursor + 11;
            long rootLength = lineLength - 12;
            long sourceCount = readUnsigned32BigEndian(input, sourcePlanStart);
            long sourceCursor = sourcePlanStart + 4;
            long source = 0;
            while (source < sourceCount) limit MAX_SOURCES {
              long pathLength = readUnsigned32BigEndian(input, sourceCursor);
              long pathStart = sourceCursor + 4;
              if (pathLength == rootLength) {
                if (sameRange(input, pathStart, rootStart, rootLength)) {
                  return source;
                }
              }

              sourceCursor += 4 + pathLength;
              long sourceLength = readUnsigned32BigEndian(input, sourceCursor);
              sourceCursor += 4 + sourceLength;
              source += 1;
            }

            return -1;
          }
        }
      }

      cursor = found + 1;
    }

    return -1;
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
          runnableKind = runnableKindLine(input, cursor, found);
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
            boolean sourceItem = false;
            if (9 < lineLength) {
              sourceItem = rangeHash(input, cursor, /* length= */ 9) == 1271526807;
            }

            if (sourceItem) {
              sourceCursor = sourcePlanStart + 4;
              long sourceIndex = 0;
              boolean matchedSource = false;
              while (sourceIndex < sourceCount) limit MAX_SOURCES {
                long sourcePathLength = readUnsigned32BigEndian(input, sourceCursor);
                long sourcePathStart = sourceCursor + 4;
                sourceCursor = sourcePathStart + sourcePathLength;
                long sourceLength = readUnsigned32BigEndian(input, sourceCursor);
                long sourceStart = sourceCursor + 4;
                if (
                  sourceLine(input, cursor, found, sourcePathStart, sourcePathLength)
                ) {
                  matchedSource = true;
                  selectedRootPath = false;
                  if (sourcePathLength == rootLength) {
                    if (sameRange(input, sourcePathStart, rootStart, rootLength)) {
                      rootSelected = true;
                      selectedRootPath = true;
                    }
                  }

                  if (selectedRootPath) {
                    rootSourceStart = sourceStart;
                    rootSourceLength = sourceLength;
                  }
                }

                sourceCursor = sourceStart + sourceLength;
                sourceIndex += 1;
              }

              if (matchedSource == false) {
                return false;
              }

              selectedSources += 1;
            } else {
              if (
                exactLine(input, cursor, found, /* length= */ 14, /* hash= */ 4023520342)
              ) {
                long externalSources = externalSourceCount(input, sourcePlanStart, sourceCount);
                if (sourceCount == selectedSources + externalSources) {
                  if (rootSelected) {
                    selected = sourceModuleMatches(
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
