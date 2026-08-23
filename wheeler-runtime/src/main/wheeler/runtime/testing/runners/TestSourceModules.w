//! Validates canonical source modules and their local import edges.

module wheeler.runtime.testing.runners.test_source_modules;

classical class TestSourceModules {
  private const long MAX_PATH_BYTES = 255;
  private const long MAX_PLAN_BYTES = 32768;
  private const long MAX_SOURCES = 64;

  /// Identifies one validated module-name range in source storage.
  public record SourceModuleText(long start, long length) {}

  private long readUnsigned32BigEndian(borrow byteview input, long offset) {
    return input[offset] * 16777216 + input[offset + 1] * 65536 + input[offset + 2] * 256
      + input[offset + 3];
  }

  private long moduleNameStart(borrow byteview input, long start, long length) {
    long cursor = start;
    long end = start + length;
    boolean scanning = true;
    while (scanning) limit MAX_PLAN_BYTES {
      if (cursor < end) {
        if (input[cursor] == 10) {
          cursor += 1;
        } else {
          if (end - cursor < 2) {
            scanning = false;
          } else {
            if (input[cursor] == 47) {
              if (input[cursor + 1] == 47) {
                while (cursor < end) limit MAX_PLAN_BYTES {
                  if (input[cursor] == 10) {
                    cursor += 1;
                    break;
                  }

                  cursor += 1;
                }
              } else {
                scanning = false;
              }
            } else {
              scanning = false;
            }
          }
        }
      } else {
        scanning = false;
      }
    }

    if (end - cursor < 10) {
      return -1;
    }

    if (input[cursor] != 109) {
      return -1;
    }

    if (input[cursor + 1] != 111) {
      return -1;
    }

    if (input[cursor + 2] != 100) {
      return -1;
    }

    if (input[cursor + 3] != 117) {
      return -1;
    }

    if (input[cursor + 4] != 108) {
      return -1;
    }

    if (input[cursor + 5] != 101) {
      return -1;
    }

    if (input[cursor + 6] != 32) {
      return -1;
    }

    return cursor + 7;
  }

  private boolean moduleInitial(long scalar) {
    if (96 < scalar) {
      return scalar < 123;
    }

    return false;
  }

  private boolean moduleContinuation(long scalar) {
    if (moduleInitial(scalar)) {
      return true;
    }

    if (47 < scalar) {
      if (scalar < 58) {
        return true;
      }
    }

    return scalar == 95;
  }

  /// Checks one canonical source preamble and dotted module declaration.
  public boolean validCanonicalSourceModule(borrow byteview input, long start, long length) {
    long cursor = moduleNameStart(input, start, length);
    if (cursor < 0) {
      return false;
    }

    long end = start + length;
    boolean segmentStart = true;
    while (cursor < end) limit MAX_PATH_BYTES {
      long scalar = input[cursor];
      if (scalar == 59) {
        if (segmentStart) {
          return false;
        }

        if (end - cursor < 2) {
          return false;
        }

        return input[cursor + 1] == 10;
      }

      if (scalar == 46) {
        if (segmentStart) {
          return false;
        }

        segmentStart = true;
      } else {
        if (segmentStart) {
          if (moduleInitial(scalar) == false) {
            return false;
          }

          segmentStart = false;
        } else {
          if (moduleContinuation(scalar) == false) {
            return false;
          }
        }
      }

      cursor += 1;
    }

    return false;
  }

  private long moduleNameLength(borrow byteview input, long start, long length) {
    long moduleStart = moduleNameStart(input, start, length);
    if (moduleStart < 0) {
      return -1;
    }

    long cursor = moduleStart;
    long end = start + length;
    while (cursor < end) limit MAX_PATH_BYTES {
      if (input[cursor] == 59) {
        return cursor - moduleStart;
      }

      cursor += 1;
    }

    return -1;
  }

  /// Returns the module-name range after canonical source validation.
  public SourceModuleText validatedSourceModuleText(
    borrow byteview input,
    long start,
    long length
  ) {
    long moduleStart = moduleNameStart(input, start, length);
    long moduleLength = moduleNameLength(input, start, length);
    assert(-1 < moduleStart);
    assert(0 < moduleLength);
    return new SourceModuleText(moduleStart, moduleLength);
  }

  private boolean sameSourceModule(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long leftModule = moduleNameStart(input, leftStart, leftLength);
    long rightModule = moduleNameStart(input, rightStart, rightLength);
    long leftModuleLength = moduleNameLength(input, leftStart, leftLength);
    long rightModuleLength = moduleNameLength(input, rightStart, rightLength);
    if (leftModuleLength != rightModuleLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftModuleLength) limit MAX_PATH_BYTES {
      if (input[leftModule + offset] != input[rightModule + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Checks that one source declares no module used by an earlier plan entry.
  public boolean uniqueSourceModule(
    borrow byteview input,
    long planStart,
    long sourceIndex,
    long sourceStart,
    long sourceLength
  ) {
    long cursor = planStart + 4;
    long prior = 0;
    while (prior < sourceIndex) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + pathLength;
      long priorSourceLength = readUnsigned32BigEndian(input, cursor);
      long priorSourceStart = cursor + 4;
      if (
        sameSourceModule(input, priorSourceStart, priorSourceLength, sourceStart, sourceLength)
      ) {
        return false;
      }

      cursor = priorSourceStart + priorSourceLength;
      prior += 1;
    }

    return true;
  }

  /// Compares a canonical source declaration with one manifest module range.
  public boolean sourceModuleMatches(
    borrow byteview input,
    long sourceStart,
    long sourceLength,
    long moduleStart,
    long moduleLength
  ) {
    long sourceModuleStart = moduleNameStart(input, sourceStart, sourceLength);
    if (sourceModuleStart < 0) {
      return false;
    }

    if (sourceStart + sourceLength < sourceModuleStart + moduleLength + 2) {
      return false;
    }

    long offset = 0;
    while (offset < moduleLength) limit MAX_PATH_BYTES {
      if (input[sourceModuleStart + offset] != input[moduleStart + offset]) {
        return false;
      }

      offset += 1;
    }

    if (input[sourceModuleStart + moduleLength] != 59) {
      return false;
    }

    return input[sourceModuleStart + moduleLength + 1] == 10;
  }

  private boolean validModuleNameRange(borrow byteview input, long start, long length) {
    if (length == 0) {
      return false;
    }

    boolean segmentStart = true;
    long offset = 0;
    while (offset < length) limit MAX_PATH_BYTES {
      long scalar = input[start + offset];
      if (scalar == 46) {
        if (segmentStart) {
          return false;
        }

        segmentStart = true;
      } else {
        if (segmentStart) {
          if (moduleInitial(scalar) == false) {
            return false;
          }

          segmentStart = false;
        } else {
          if (moduleContinuation(scalar) == false) {
            return false;
          }
        }
      }

      offset += 1;
    }

    return segmentStart == false;
  }

  private boolean moduleRangeMatchesSource(
    borrow byteview input,
    long moduleStart,
    long moduleLength,
    long sourceStart,
    long sourceLength
  ) {
    long sourceModule = moduleNameStart(input, sourceStart, sourceLength);
    long sourceModuleLength = moduleNameLength(input, sourceStart, sourceLength);
    if (moduleLength != sourceModuleLength) {
      return false;
    }

    long offset = 0;
    while (offset < moduleLength) limit MAX_PATH_BYTES {
      if (input[moduleStart + offset] != input[sourceModule + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private boolean moduleInPlan(
    borrow byteview input,
    long planStart,
    long sourceCount,
    long moduleStart,
    long moduleLength
  ) {
    long cursor = planStart + 4;
    long source = 0;
    while (source < sourceCount) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + pathLength;
      long sourceLength = readUnsigned32BigEndian(input, cursor);
      long sourceStart = cursor + 4;
      if (
        moduleRangeMatchesSource(input, moduleStart, moduleLength, sourceStart, sourceLength)
      ) {
        return true;
      }

      cursor = sourceStart + sourceLength;
      source += 1;
    }

    return false;
  }

  private long compareModuleRange(
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

  private boolean validSourceImports(
    borrow byteview input,
    long planStart,
    long sourceCount,
    long sourceStart,
    long sourceLength
  ) {
    long ownModuleStart = moduleNameStart(input, sourceStart, sourceLength);
    long ownModuleLength = moduleNameLength(input, sourceStart, sourceLength);
    long cursor = ownModuleStart + ownModuleLength + 2;
    long end = sourceStart + sourceLength;
    long importCount = 0;
    long previousImportStart = 0;
    long previousImportLength = 0;
    boolean scanning = true;
    while (scanning) limit MAX_SOURCES {
      while (cursor < end) limit MAX_PLAN_BYTES {
        if (input[cursor] == 10) {
          cursor += 1;
        } else {
          break;
        }
      }

      if (end - cursor < 8) {
        scanning = false;
      } else {
        boolean imported = input[cursor] == 105;
        if (imported) {
          imported = input[cursor + 1] == 109;
        }

        if (imported) {
          imported = input[cursor + 2] == 112;
        }

        if (imported) {
          imported = input[cursor + 3] == 111;
        }

        if (imported) {
          imported = input[cursor + 4] == 114;
        }

        if (imported) {
          imported = input[cursor + 5] == 116;
        }

        if (imported) {
          imported = input[cursor + 6] == 32;
        }

        if (imported == false) {
          scanning = false;
        } else {
          long importStart = cursor + 7;
          long importEnd = importStart;
          while (importEnd < end) limit MAX_PATH_BYTES {
            if (input[importEnd] == 59) {
              break;
            }

            importEnd += 1;
          }

          if (end - importEnd < 2) {
            return false;
          }

          if (input[importEnd] != 59) {
            return false;
          }

          if (input[importEnd + 1] != 10) {
            return false;
          }

          long importLength = importEnd - importStart;
          if (validModuleNameRange(input, importStart, importLength) == false) {
            return false;
          }

          if (0 < importCount) {
            if (
              compareModuleRange(
                input,
                previousImportStart,
                previousImportLength,
                importStart,
                importLength
              ) != - 1
            ) {
              return false;
            }
          }

          if (
            moduleRangeMatchesSource(
              input,
              importStart,
              importLength,
              sourceStart,
              sourceLength
            )
          ) {
            return false;
          }

          if (
            moduleInPlan(input, planStart, sourceCount, importStart, importLength) == false
          ) {
            return false;
          }

          previousImportStart = importStart;
          previousImportLength = importLength;
          importCount += 1;
          cursor = importEnd + 2;
        }
      }
    }

    return true;
  }

  private long sourceBit(long source) {
    long shift = source % 32;
    long bit = 1;
    long offset = 0;
    while (offset < shift) limit 31 {
      bit = bit * 2;
      offset += 1;
    }

    return bit;
  }

  private boolean sourceSetContains(long low, long high, long source) {
    long bit = sourceBit(source);
    if (source < 32) {
      return(low & bit) == bit;
    }

    return(high & bit) == bit;
  }

  private long moduleIndex(
    borrow byteview input,
    long planStart,
    long sourceCount,
    long moduleStart,
    long moduleLength
  ) {
    long cursor = planStart + 4;
    long source = 0;
    while (source < sourceCount) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + pathLength;
      long sourceLength = readUnsigned32BigEndian(input, cursor);
      long sourceStart = cursor + 4;
      if (
        moduleRangeMatchesSource(input, moduleStart, moduleLength, sourceStart, sourceLength)
      ) {
        return source;
      }

      cursor = sourceStart + sourceLength;
      source += 1;
    }

    return -1;
  }

  /// Rejects cycles in the completely validated local import graph.
  public boolean validAcyclicImports(borrow byteview input, long start, long sourceCount) {
    long root = 0;
    while (root < sourceCount) limit MAX_SOURCES {
      long rootBit = sourceBit(root);
      long visitedLow = 0;
      long visitedHigh = 0;
      long frontierLow = 0;
      long frontierHigh = 0;
      if (root < 32) {
        visitedLow = rootBit;
        frontierLow = rootBit;
      } else {
        visitedHigh = rootBit;
        frontierHigh = rootBit;
      }

      boolean active = frontierLow != 0;
      if (active == false) {
        active = frontierHigh != 0;
      }

      while (active) limit MAX_SOURCES {
        long nextLow = 0;
        long nextHigh = 0;
        long planCursor = start + 4;
        long source = 0;
        while (source < sourceCount) limit MAX_SOURCES {
          long pathLength = readUnsigned32BigEndian(input, planCursor);
          planCursor += 4 + pathLength;
          long sourceLength = readUnsigned32BigEndian(input, planCursor);
          long sourceStart = planCursor + 4;
          if (sourceSetContains(frontierLow, frontierHigh, source)) {
            long ownModuleStart = moduleNameStart(input, sourceStart, sourceLength);
            long ownModuleLength = moduleNameLength(input, sourceStart, sourceLength);
            long importCursor = ownModuleStart + ownModuleLength + 2;
            long sourceEnd = sourceStart + sourceLength;
            boolean scanning = true;
            while (scanning) limit MAX_SOURCES {
              while (importCursor < sourceEnd) limit MAX_PLAN_BYTES {
                if (input[importCursor] == 10) {
                  importCursor += 1;
                } else {
                  break;
                }
              }

              if (sourceEnd - importCursor < 8) {
                scanning = false;
              } else {
                boolean imported = input[importCursor] == 105;
                if (imported) {
                  imported = input[importCursor + 1] == 109;
                }

                if (imported) {
                  imported = input[importCursor + 2] == 112;
                }

                if (imported) {
                  imported = input[importCursor + 3] == 111;
                }

                if (imported) {
                  imported = input[importCursor + 4] == 114;
                }

                if (imported) {
                  imported = input[importCursor + 5] == 116;
                }

                if (imported) {
                  imported = input[importCursor + 6] == 32;
                }

                if (imported == false) {
                  scanning = false;
                } else {
                  long importStart = importCursor + 7;
                  long importEnd = importStart;
                  while (input[importEnd] != 59) limit MAX_PATH_BYTES {
                    importEnd += 1;
                  }

                  long target = moduleIndex(
                    input,
                    start,
                    sourceCount,
                    importStart,
                    importEnd - importStart
                  );
                  if (target == root) {
                    return false;
                  }

                  if (sourceSetContains(visitedLow, visitedHigh, target) == false) {
                    long targetBit = sourceBit(target);
                    if (target < 32) {
                      visitedLow += targetBit;
                      nextLow += targetBit;
                    } else {
                      visitedHigh += targetBit;
                      nextHigh += targetBit;
                    }
                  }

                  importCursor = importEnd + 2;
                }
              }
            }
          }

          planCursor = sourceStart + sourceLength;
          source += 1;
        }

        frontierLow = nextLow;
        frontierHigh = nextHigh;
        active = frontierLow != 0;
        if (active == false) {
          active = frontierHigh != 0;
        }
      }

      root += 1;
    }

    return true;
  }

  /// Checks every source import against the complete canonical source plan.
  public boolean validPlanImports(borrow byteview input, long start, long sourceCount) {
    long cursor = start + 4;
    long source = 0;
    while (source < sourceCount) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + pathLength;
      long sourceLength = readUnsigned32BigEndian(input, cursor);
      long sourceStart = cursor + 4;
      if (
        validSourceImports(input, start, sourceCount, sourceStart, sourceLength) == false
      ) {
        return false;
      }

      cursor = sourceStart + sourceLength;
      source += 1;
    }

    return true;
  }

}
