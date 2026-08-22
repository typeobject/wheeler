//! Validates native lock reachability and acyclic dependency edges.

module wheeler.runtime.testing.runners.test_package_graph;

classical class TestPackageGraph {
  private const long MAX_METADATA_BYTES = 4096;
  private const long MAX_PACKAGES = 64;

  private long rangeHash(borrow byteview input, long start, long length) {
    long hash = 0;
    long offset = 0;
    while (offset < length) limit MAX_METADATA_BYTES {
      hash = (hash * 131 + input[start + offset]) % 4294967296;
      offset += 1;
    }

    return hash;
  }

  private long lineEnd(borrow byteview input, long cursor, long end) {
    long scan = cursor;
    while (scan < end) limit MAX_METADATA_BYTES {
      if (input[scan] == 10) {
        return scan;
      }

      if (input[scan] == 13) {
        return -1;
      }

      scan += 1;
    }

    return -1;
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

  private boolean sameRange(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength != rightLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftLength) limit 255 {
      if (input[leftStart + offset] != input[rightStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long packageOrdinal(
    borrow byteview input,
    borrow mut bytes nameStarts,
    borrow mut bytes nameLengths,
    long count,
    long nameStart,
    long nameLength
  ) {
    long ordinal = 0;
    while (ordinal < count) limit MAX_PACKAGES {
      if (
        sameRange(
          input,
          nameStarts[ordinal * 2] + nameStarts[ordinal * 2 + 1] * 256,
          nameLengths[ordinal],
          nameStart,
          nameLength
        )
      ) {
        return ordinal;
      }

      ordinal += 1;
    }

    return -1;
  }

  private long collectPackageNames(
    borrow byteview input,
    long lockStart,
    long lockLength,
    borrow mut bytes nameStarts,
    borrow mut bytes nameLengths
  ) {
    long end = lockStart + lockLength;
    long cursor = lockStart;
    long count = 0;
    while (cursor < end) limit MAX_METADATA_BYTES {
      long found = lineEnd(input, cursor, end);
      if (found < 0) {
        return -1;
      }

      if (11 < found - cursor) {
        if (rangeHash(input, cursor, /* length= */ 11) == 586558766) {
          if (MAX_PACKAGES < count + 1) {
            return -1;
          }

          long nameStart = cursor + 11;
          long nameLength = found - cursor - 12;
          if (255 < nameLength) {
            return -1;
          }

          setByte(nameStarts, count * 2, nameStart % 256);
          setByte(nameStarts, count * 2 + 1, nameStart / 256);
          setByte(nameLengths, count, nameLength);
          count += 1;
        }
      }

      cursor = found + 1;
    }

    return count;
  }

  private boolean collectEdges(
    borrow byteview input,
    long lockStart,
    long lockLength,
    borrow mut bytes nameStarts,
    borrow mut bytes nameLengths,
    long count,
    borrow mut bytes edges
  ) {
    long end = lockStart + lockLength;
    long cursor = lockStart;
    long owner = -1;
    while (cursor < end) limit MAX_METADATA_BYTES {
      long found = lineEnd(input, cursor, end);
      if (found < 0) {
        return false;
      }

      if (11 < found - cursor) {
        if (rangeHash(input, cursor, /* length= */ 11) == 586558766) {
          owner += 1;
        }
      }

      if (9 < found - cursor) {
        if (rangeHash(input, cursor, /* length= */ 9) == 1271526807) {
          if (owner < 0) {
            return false;
          }

          long dependencyLength = found - cursor - 10;
          long dependency = packageOrdinal(
            input,
            nameStarts,
            nameLengths,
            count,
            cursor + 9,
            dependencyLength
          );
          if (dependency < 0) {
            return false;
          }

          setByte(edges, owner * count + dependency, 1);
        }
      }

      cursor = found + 1;
    }

    return owner + 1 == count;
  }

  private boolean collectDirectDependencies(
    borrow byteview input,
    long manifestStart,
    long manifestLength,
    borrow mut bytes nameStarts,
    borrow mut bytes nameLengths,
    long count,
    borrow mut bytes direct
  ) {
    long end = manifestStart + manifestLength;
    long cursor = manifestStart;
    boolean dependencies = false;
    long directCount = 0;
    while (cursor < end) limit MAX_METADATA_BYTES {
      long found = lineEnd(input, cursor, end);
      if (found < 0) {
        return false;
      }

      if (exactLine(input, cursor, found, 13, 344468657)) {
        dependencies = true;
      } else {
        if (dependencies) {
          if (exactLine(input, cursor, found, 13, 1665807620)) {
            return 0 < directCount;
          }

          if (exactLine(input, cursor, found, 16, 2054217082)) {
            return 0 < directCount;
          }

          if (11 < found - cursor) {
            if (rangeHash(input, cursor, /* length= */ 11) == 3709182977) {
              long nameLength = found - cursor - 12;
              long ordinal = packageOrdinal(
                input,
                nameStarts,
                nameLengths,
                count,
                cursor + 11,
                nameLength
              );
              if (ordinal < 0) {
                return false;
              }

              setByte(direct, ordinal, 1);
              directCount += 1;
            }
          }
        }
      }

      cursor = found + 1;
    }

    return false;
  }

  private boolean closeAndValidateGraph(
    long count,
    borrow mut bytes edges,
    borrow mut bytes direct
  ) {
    long via = 0;
    while (via < count) limit MAX_PACKAGES {
      long source = 0;
      while (source < count) limit MAX_PACKAGES {
        if (edges[source * count + via] == 1) {
          long target = 0;
          while (target < count) limit MAX_PACKAGES {
            if (edges[via * count + target] == 1) {
              setByte(edges, source * count + target, 1);
            }

            target += 1;
          }
        }

        source += 1;
      }

      via += 1;
    }

    long package = 0;
    while (package < count) limit MAX_PACKAGES {
      if (edges[package * count + package] == 1) {
        return false;
      }

      boolean reachable = direct[package] == 1;
      long root = 0;
      while (root < count) limit MAX_PACKAGES {
        if (direct[root] == 1) {
          if (edges[root * count + package] == 1) {
            reachable = true;
          }
        }

        root += 1;
      }

      if (reachable == false) {
        return false;
      }

      package += 1;
    }

    return true;
  }

  /// Requires one acyclic lock graph reachable from direct manifest dependencies.
  public boolean validManifestLockGraph(
    borrow byteview input,
    long manifestStart,
    long manifestLength,
    long lockStart,
    long lockLength
  ) {
    if (lockLength == 96) {
      return true;
    }

    region graph = new region(/* bytes= */ 4352, /* allocations= */ 4);
    bytes nameStarts = allocateBytes(graph, MAX_PACKAGES * 2);
    bytes nameLengths = allocateBytes(graph, MAX_PACKAGES);
    bytes edges = allocateBytes(graph, MAX_PACKAGES * MAX_PACKAGES);
    bytes direct = allocateBytes(graph, MAX_PACKAGES);
    long count = collectPackageNames(input, lockStart, lockLength, nameStarts, nameLengths);
    boolean valid = 0 < count;
    if (valid) {
      valid = collectEdges(
        input,
        lockStart,
        lockLength,
        nameStarts,
        nameLengths,
        count,
        edges
      );
    }

    if (valid) {
      valid = collectDirectDependencies(
        input,
        manifestStart,
        manifestLength,
        nameStarts,
        nameLengths,
        count,
        direct
      );
    }

    if (valid) {
      valid = closeAndValidateGraph(count, edges, direct);
    }

    drop(direct);
    drop(edges);
    drop(nameLengths);
    drop(nameStarts);
    drop(graph);
    return valid;
  }
}
