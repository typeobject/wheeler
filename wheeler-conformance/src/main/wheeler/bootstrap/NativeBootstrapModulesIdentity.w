//! Verifies and identifies a bounded canonical bootstrap module closure.

module wheeler.conformance.bootstrap.modules_identity;

import wheeler.conformance.bootstrap.syntax;
import wheeler.crypto.content_identity;

classical class NativeBootstrapModulesIdentity {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_EXTERNAL_MODULES = 64;
  private const long MAX_IMPORTS_PER_MODULE = 64;
  private const long MAX_IMPORTS = 1536;
  private const long MAX_MANIFEST_BYTES = 131072;
  private const long MODULE_ARENA_BYTES = 2359296;

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

    if (scalar == 95) {
      valid = true;
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
    if (leftLength == rightLength) {} else {
      return false;
    }

    long index = 0;
    while (index < leftLength) limit 128 {
      if ((source[left + index] == source[right + index]) == false) {
        return false;
      }

      index += 1;
    }

    return true;
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
    while (index < common) limit 128 {
      if (source[previous + index] < source[current + index]) {
        return true;
      }

      if (source[current + index] < source[previous + index]) {
        return false;
      }

      index += 1;
    }

    return previousLength < currentLength;
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
    return -1 < listedIndex(source, starts, lengths, count, candidate, candidateLength);
  }

  private boolean samePath(
    borrow byteview source,
    long left,
    long leftLength,
    long right,
    long rightLength
  ) {
    if (leftLength == rightLength) {} else {
      return false;
    }

    long index = 0;
    while (index < leftLength) limit 256 {
      if ((source[left + index] == source[right + index]) == false) {
        return false;
      }

      index += 1;
    }

    return true;
  }

  private long listedIndex(
    borrow byteview source,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long candidate,
    long candidateLength
  ) {
    long low = 0;
    long high = count;
    while (low < high) limit MAX_LOCAL_MODULES {
      long middle = (low + high) / 2;
      if (
        sameText(source, starts[middle], lengths[middle], candidate, candidateLength)
      ) {
        return middle;
      }

      if (
        orderedAfter(source, starts[middle], lengths[middle], candidate, candidateLength)
      ) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    return -1;
  }

  /// Publishes SHA-256 for up to 512 rooted modules and sixty-four externals.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < MAX_MANIFEST_BYTES + 1, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(/* bytes= */ MODULE_ARENA_BYTES, /* allocations= */ 23);
    bytes expected = allocateBytes(arena, /* length= */ 256);
    words externalStarts = allocate(arena, MAX_EXTERNAL_MODULES);
    words externalLengths = allocate(arena, MAX_EXTERNAL_MODULES);
    words moduleStarts = allocate(arena, MAX_LOCAL_MODULES);
    words moduleLengths = allocate(arena, MAX_LOCAL_MODULES);
    words sourceStarts = allocate(arena, MAX_LOCAL_MODULES);
    words sourceLengths = allocate(arena, MAX_LOCAL_MODULES);
    words edgeOwners = allocate(arena, MAX_IMPORTS);
    words edgeStarts = allocate(arena, MAX_IMPORTS);
    words edgeLengths = allocate(arena, MAX_IMPORTS);
    words adjacency = allocate(arena, MAX_LOCAL_MODULES * MAX_LOCAL_MODULES);
    words incoming = allocate(arena, MAX_LOCAL_MODULES);
    words removed = allocate(arena, MAX_LOCAL_MODULES);
    words reachable = allocate(arena, MAX_LOCAL_MODULES);

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
      while (moreExternals) limit MAX_EXTERNAL_MODULES {
        requireMetadata(parsedExternals < MAX_EXTERNAL_MODULES, source);
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
    long parsedModules = 0;
    long parsedImports = 0;
    boolean moreModules = true;
    while (moreModules) limit MAX_LOCAL_MODULES {
      requireMetadata(parsedModules < MAX_LOCAL_MODULES, source);
      long moduleStart = cursor;
      cursor = consumeModuleName(source, cursor);
      long moduleLength = cursor - moduleStart;
      if (0 < parsedModules) {
        requireMetadata(
          orderedAfter(
            source,
            moduleStarts[parsedModules - 1],
            moduleLengths[parsedModules - 1],
            moduleStart,
            moduleLength
          ),
          source
        );
      }

      set(moduleStarts, parsedModules, moduleStart);
      set(moduleLengths, parsedModules, moduleLength);

      setByte(expected, 0, 34);
      setByte(expected, 1, 10);
      writeAscii(expected, 2, "    source: ");
      setByte(expected, 14, 34);
      cursor = consumeMetadata(source, cursor, expected, 15);
      long sourceStart = cursor;
      cursor = consumeSourcePath(source, cursor);
      long sourceLength = cursor - sourceStart;
      long previousSource = 0;
      while (previousSource < parsedModules) limit MAX_LOCAL_MODULES {
        requireMetadata(
          samePath(
            source,
            sourceStarts[previousSource],
            sourceLengths[previousSource],
            sourceStart,
            sourceLength
          ) == false,
          source
        );
        previousSource += 1;
      }

      set(sourceStarts, parsedModules, sourceStart);
      set(sourceLengths, parsedModules, sourceLength);

      setByte(expected, 0, 34);
      setByte(expected, 1, 10);
      writeAscii(expected, 2, "    identity: ");
      cursor = consumeMetadata(source, cursor, expected, 16);
      cursor = consumeQuotedIdentity(source, cursor, expected);
      setByte(expected, 0, 10);
      writeAscii(expected, 1, "    imports:");
      cursor = consumeMetadata(source, cursor, expected, 13);

      long moduleImportCount = 0;
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
        while (moreImports) limit MAX_IMPORTS_PER_MODULE {
          requireMetadata(moduleImportCount < MAX_IMPORTS_PER_MODULE, source);
          requireMetadata(parsedImports < MAX_IMPORTS, source);
          long importStart = cursor;
          cursor = consumeModuleName(source, cursor);
          long importLength = cursor - importStart;
          if (0 < moduleImportCount) {
            requireMetadata(
              orderedAfter(
                source,
                edgeStarts[parsedImports - 1],
                edgeLengths[parsedImports - 1],
                importStart,
                importLength
              ),
              source
            );
          }

          set(edgeOwners, parsedImports, parsedModules);
          set(edgeStarts, parsedImports, importStart);
          set(edgeLengths, parsedImports, importLength);
          parsedImports += 1;
          moduleImportCount += 1;
          setByte(expected, 0, 34);
          setByte(expected, 1, 10);
          cursor = consumeMetadata(source, cursor, expected, 2);
          moreImports = false;
          if (cursor + 2 < bufferLength(source)) {
            moreImports = source[cursor + 2] == 32;
          }

          if (moreImports) {
            writeAscii(expected, 0, "      - ");
            setByte(expected, 8, 34);
            cursor = consumeMetadata(source, cursor, expected, 9);
          }
        }
      }

      parsedModules += 1;
      moreModules = cursor < bufferLength(source);
      if (moreModules) {
        writeAscii(expected, 0, "  - name: ");
        setByte(expected, 10, 34);
        cursor = consumeMetadata(source, cursor, expected, 11);
      }
    }

    requireMetadata(0 < parsedModules, source);
    long rootModule = listedIndex(
      source,
      moduleStarts,
      moduleLengths,
      parsedModules,
      rootStart,
      rootLength
    );
    requireMetadata(-1 < rootModule, source);
    long external = 0;
    while (external < parsedExternals) limit MAX_EXTERNAL_MODULES {
      requireMetadata(
        listedIndex(
          source,
          moduleStarts,
          moduleLengths,
          parsedModules,
          externalStarts[external],
          externalLengths[external]
        ) < 0,
        source
      );
      external += 1;
    }

    long edge = 0;
    while (edge < parsedImports) limit MAX_IMPORTS {
      long localTarget = listedIndex(
        source,
        moduleStarts,
        moduleLengths,
        parsedModules,
        edgeStarts[edge],
        edgeLengths[edge]
      );
      boolean resolved = -1 < localTarget;
      if (resolved == false) {
        resolved = listed(
          source,
          externalStarts,
          externalLengths,
          parsedExternals,
          edgeStarts[edge],
          edgeLengths[edge]
        );
      }

      requireMetadata(resolved, source);
      if (-1 < localTarget) {
        requireMetadata((localTarget == edgeOwners[edge]) == false, source);
        long adjacencyIndex = edgeOwners[edge] * MAX_LOCAL_MODULES + localTarget;
        if (adjacency[adjacencyIndex] == 0) {
          set(adjacency, adjacencyIndex, 1);
          set(incoming, localTarget, incoming[localTarget] + 1);
        }
      }

      edge += 1;
    }

    set(reachable, rootModule, 1);
    long processed = 0;
    while (processed < parsedModules) limit MAX_LOCAL_MODULES {
      long candidate = -1;
      long module = 0;
      while (module < parsedModules) limit MAX_LOCAL_MODULES {
        if (removed[module] == 0) {
          if (incoming[module] == 0) {
            if (candidate < 0) {
              candidate = module;
            }
          }
        }

        module += 1;

      }

      requireMetadata(-1 < candidate, source);
      set(removed, candidate, 1);
      long dependency = 0;
      while (dependency < parsedModules) limit MAX_LOCAL_MODULES {
        if (adjacency[candidate * MAX_LOCAL_MODULES + dependency] == 1) {
          set(incoming, dependency, incoming[dependency] - 1);
          if (reachable[candidate] == 1) {
            set(reachable, dependency, 1);
          }
        }

        dependency += 1;
      }

      processed += 1;
    }

    long reached = 0;
    while (reached < parsedModules) limit MAX_LOCAL_MODULES {
      requireMetadata(reachable[reached] == 1, source);
      reached += 1;
    }

    requireMetadata(cursor == bufferLength(source), source);
    publishSha256(source, identity, arena);
    moduleCount = parsedModules;
    externalCount = parsedExternals;
    importCount = parsedImports;
    published = 1;
    setOutputLength(identity, 32);
    drop(reachable);
    drop(removed);
    drop(incoming);
    drop(adjacency);
    drop(edgeLengths);
    drop(edgeStarts);
    drop(edgeOwners);
    drop(sourceLengths);
    drop(sourceStarts);
    drop(moduleLengths);
    drop(moduleStarts);
    drop(externalLengths);
    drop(externalStarts);
    drop(expected);
    drop(arena);
  }
}
