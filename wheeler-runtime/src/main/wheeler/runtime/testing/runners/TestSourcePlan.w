//! Validates canonical modular target-source framing before case execution.

module wheeler.runtime.testing.runners.test_source_plan;

import wheeler.runtime.testing.runners.test_source_modules;

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

  private boolean continuation(long scalar) {
    if (127 < scalar) {
      return scalar < 192;
    }

    return false;
  }

  private boolean validUtf8(borrow byteview input, long start, long length) {
    long cursor = start;
    long end = start + length;
    long second = 0;
    while (cursor < end) limit MAX_PLAN_BYTES {
      long first = input[cursor];
      if (first < 128) {
        cursor += 1;
      } else {
        if (193 < first) {
          if (first < 224) {
            if (end - cursor < 2) {
              return false;
            }

            if (continuation(input[cursor + 1]) == false) {
              return false;
            }

            cursor += 2;
          } else {
            if (first < 240) {
              if (end - cursor < 3) {
                return false;
              }

              second = input[cursor + 1];
              if (continuation(second) == false) {
                return false;
              }

              if (continuation(input[cursor + 2]) == false) {
                return false;
              }

              if (first == 224) {
                if (second < 160) {
                  return false;
                }
              }

              if (first == 237) {
                if (159 < second) {
                  return false;
                }
              }

              cursor += 3;
            } else {
              if (first < 245) {
                if (end - cursor < 4) {
                  return false;
                }

                second = input[cursor + 1];
                if (continuation(second) == false) {
                  return false;
                }

                if (continuation(input[cursor + 2]) == false) {
                  return false;
                }

                if (continuation(input[cursor + 3]) == false) {
                  return false;
                }

                if (first == 240) {
                  if (second < 144) {
                    return false;
                  }
                }

                if (first == 244) {
                  if (143 < second) {
                    return false;
                  }
                }

                cursor += 4;
              } else {
                return false;
              }
            }
          }
        } else {
          return false;
        }
      }
    }

    return cursor == end;
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

  private long validatedSourceLengthOffset(
    borrow byteview input,
    long start,
    long length,
    long ordinal
  ) {
    assert(0 < length);
    long sourceCount = readUnsigned32BigEndian(input, start);
    assert(ordinal < sourceCount);
    long cursor = start + 4;
    long source = 0;
    while (source < ordinal) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + pathLength;
      long sourceLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + sourceLength;
      source += 1;
    }

    long selectedPathLength = readUnsigned32BigEndian(input, cursor);
    return cursor + 4 + selectedPathLength;
  }

  /// Returns the source count from a previously validated plan.
  public long validatedSourceCount(borrow byteview input, long start, long length) {
    assert(0 < length);
    return readUnsigned32BigEndian(input, start);
  }

  /// Returns one source length from a previously validated plan.
  public long validatedSourceLength(
    borrow byteview input,
    long start,
    long length,
    long ordinal
  ) {
    long sourceLengthOffset = validatedSourceLengthOffset(input, start, length, ordinal);
    return readUnsigned32BigEndian(input, sourceLengthOffset);
  }

  /// Returns one source start from a previously validated plan.
  public long validatedSourceStart(borrow byteview input, long start, long length, long ordinal) {
    return validatedSourceLengthOffset(input, start, length, ordinal) + 4;
  }

  /// Copies one source from a previously validated plan.
  public void copyValidatedSource(
    borrow byteview input,
    long start,
    long length,
    long ordinal,
    borrow mut bytes output
  ) {
    long sourceLengthOffset = validatedSourceLengthOffset(input, start, length, ordinal);
    long sourceLength = readUnsigned32BigEndian(input, sourceLengthOffset);
    assert(bufferLength(output) == sourceLength);
    long sourceStart = sourceLengthOffset + 4;
    long offset = 0;
    while (offset < sourceLength) limit MAX_PLAN_BYTES {
      setByte(output, offset, input[sourceStart + offset]);
      offset += 1;
    }
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

      if (validUtf8(input, cursor, sourceLength) == false) {
        return false;
      }

      if (validCanonicalSourceModule(input, cursor, sourceLength) == false) {
        return false;
      }

      if (uniqueSourceModule(input, start, source, cursor, sourceLength) == false) {
        return false;
      }

      previousPathStart = pathStart;
      previousPathLength = pathLength;
      cursor += sourceLength;
      source += 1;
    }

    if (cursor != end) {
      return false;
    }

    if (validPlanImports(input, start, sourceCount) == false) {
      return false;
    }

    return validAcyclicImports(input, start, sourceCount);
  }
}
