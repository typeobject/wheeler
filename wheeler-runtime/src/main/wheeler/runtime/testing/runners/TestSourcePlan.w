//! Validates canonical modular target-source framing before case execution.

module wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourcePlan {
  private const long MAX_PATH_BYTES = 255;
  private const long MAX_PLAN_BYTES = 32768;
  private const long MAX_SOURCES = 64;

  private long readUnsigned32BigEndian(borrow byteview input, long offset) {
    return input[offset] * 16777216 + input[offset + 1] * 65536 + input[offset + 2] * 256
      + input[offset + 3];
  }

  private boolean pathScalar(long scalar) {
    if (47 < scalar) {
      if (scalar < 58) {
        return true;
      }
    }

    if (64 < scalar) {
      if (scalar < 91) {
        return true;
      }
    }

    if (96 < scalar) {
      if (scalar < 123) {
        return true;
      }
    }

    if (scalar == 45) {
      return true;
    }

    if (scalar == 46) {
      return true;
    }

    if (scalar == 47) {
      return true;
    }

    return scalar == 95;
  }

  private boolean validPath(borrow byteview input, long start, long length) {
    if (length < 3) {
      return false;
    }

    if (input[start] == 47) {
      return false;
    }

    if (input[start + length - 2] != 46) {
      return false;
    }

    if (input[start + length - 1] != 119) {
      return false;
    }

    long offset = 0;
    long segmentStart = start;
    long segmentLength = 0;
    while (offset < length) limit MAX_PATH_BYTES {
      long scalar = input[start + offset];
      if (pathScalar(scalar) == false) {
        return false;
      }

      if (scalar == 47) {
        if (segmentLength == 0) {
          return false;
        }

        if (segmentLength == 1) {
          if (input[segmentStart] == 46) {
            return false;
          }
        }

        if (segmentLength == 2) {
          if (input[segmentStart] == 46) {
            if (input[segmentStart + 1] == 46) {
              return false;
            }
          }
        }

        segmentStart = start + offset + 1;
        segmentLength = 0;
      } else {
        segmentLength += 1;
      }

      offset += 1;
    }

    return 0 < segmentLength;
  }

  private long comparePath(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long offset = 0;
    while (offset < shared) limit MAX_PATH_BYTES {
      long left = input[leftStart + offset];
      long right = input[rightStart + offset];
      if (left < right) {
        return -1;
      }

      if (right < left) {
        return 1;
      }

      offset += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  /// Checks exact bounded count, paths, ordering, and source boundaries.
  public boolean validTargetSourcePlan(borrow byteview input, long start, long length) {
    if (length < 13) {
      return false;
    }

    if (MAX_PLAN_BYTES < length) {
      return false;
    }

    long end = start + length;
    if (bufferLength(input) < end) {
      return false;
    }

    long sourceCount = readUnsigned32BigEndian(input, start);
    if (sourceCount == 0) {
      return false;
    }

    if (MAX_SOURCES < sourceCount) {
      return false;
    }

    long cursor = start + 4;
    long source = 0;
    long previousPathStart = 0;
    long previousPathLength = 0;
    while (source < sourceCount) limit MAX_SOURCES {
      if (end - cursor < 9) {
        return false;
      }

      long pathLength = readUnsigned32BigEndian(input, cursor);
      if (pathLength == 0) {
        return false;
      }

      if (MAX_PATH_BYTES < pathLength) {
        return false;
      }

      cursor += 4;
      if (end - cursor < pathLength + 4) {
        return false;
      }

      long pathStart = cursor;
      if (validPath(input, pathStart, pathLength) == false) {
        return false;
      }

      if (0 < source) {
        if (
          comparePath(input, previousPathStart, previousPathLength, pathStart, pathLength) != - 1
        ) {
          return false;
        }
      }

      cursor += pathLength;
      long sourceLength = readUnsigned32BigEndian(input, cursor);
      if (sourceLength == 0) {
        return false;
      }

      cursor += 4;
      if (end - cursor < sourceLength) {
        return false;
      }

      previousPathStart = pathStart;
      previousPathLength = pathLength;
      cursor += sourceLength;
      source += 1;
    }

    return cursor == end;
  }
}
