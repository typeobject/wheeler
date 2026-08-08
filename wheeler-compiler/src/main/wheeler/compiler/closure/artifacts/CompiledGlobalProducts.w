//! Decodes source-local globals into one counted closure product window.

module wheeler.compiler.closure.compiled_global_products;

import wheeler.core.encoding.binary;

classical class CompiledGlobalProducts {
  private const long GLOBAL_ROWS = 20480;
  private const long MAX_GLOBALS = 4096;
  private const long MAX_MODULES = 512;
  private const long MAX_SECTIONS = 64;
  private const long STAGING_BYTES = 131072;

  private record TypeSection(long start, long length) {}

  private TypeSection typeSection(borrow byteview artifact, long artifactLength) {
    assert(39 < artifactLength);
    assert(artifact[0] == 87);
    assert(artifact[1] == 72);
    assert(artifact[2] == 69);
    assert(artifact[3] == 69);
    assert(artifact[4] == 76);
    assert(artifact[5] == 66);
    assert(artifact[6] == 67);
    assert(artifact[7] == 0);
    assert(readUnsigned(artifact, 8, 2) == 1);
    assert(readUnsigned(artifact, 10, 2) == 0);
    assert(readUnsigned(artifact, 16, 8) == artifactLength);
    long sectionCount = readUnsigned(artifact, 24, 4);
    assert(0 < sectionCount);
    assert(sectionCount < MAX_SECTIONS + 1);
    assert(readUnsigned(artifact, 28, 4) == 32);
    assert(readUnsigned(artifact, 32, 8) == 40);
    long previousType = 0;
    long previousEnd = 40 + sectionCount * 32;
    long selectedStart = -1;
    long selectedLength = 0;
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      long directory = 40 + section * 32;
      long type = readUnsigned(artifact, directory, 4);
      long flags = readUnsigned(artifact, directory + 4, 4);
      long start = readUnsigned(artifact, directory + 8, 8);
      long length = readUnsigned(artifact, directory + 16, 8);
      assert(previousType < type);
      assert(flags == 1);
      assert(readUnsigned(artifact, directory + 24, 4) == 8);
      assert(readUnsigned(artifact, directory + 28, 4) == 0);
      assert(start % 8 == 0);
      assert(previousEnd < start + 1);
      assert(start < artifactLength + 1);
      assert(length < artifactLength - start + 1);
      previousType = type;
      previousEnd = start + length;
      if (type == 3) {
        selectedStart = start;
        selectedLength = length;
      }

      section += 1;
    }

    assert(-1 < selectedStart);
    return new TypeSection(selectedStart, selectedLength);
  }

  /// Appends one exact globals prefix after validating every row.
  public long appendCompiledGlobalProducts(
    borrow byteview artifact,
    long artifactLength,
    long moduleOwner,
    long moduleStringBase,
    long moduleStringCount,
    long closureGlobalCount,
    borrow mut words closureGlobals
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < MAX_MODULES);
    assert(-1 < moduleStringBase);
    assert(-1 < moduleStringCount);
    assert(-1 < closureGlobalCount);
    assert(closureGlobalCount < MAX_GLOBALS + 1);
    assert(bufferLength(closureGlobals) == GLOBAL_ROWS);
    TypeSection types = typeSection(artifact, artifactLength);
    assert(3 < types.length);
    long globalCount = readUnsigned(artifact, types.start, 4);
    assert(globalCount < MAX_GLOBALS - closureGlobalCount + 1);
    assert(globalCount * 16 < types.length - 4 + 1);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 4);
    words names = allocate(staging, MAX_GLOBALS);
    words typeCodes = allocate(staging, MAX_GLOBALS);
    words lowValues = allocate(staging, MAX_GLOBALS);
    words highValues = allocate(staging, MAX_GLOBALS);
    long global = 0;
    while (global < globalCount) limit MAX_GLOBALS {
      long cursor = types.start + 4 + global * 16;
      long name = readUnsigned(artifact, cursor, 4);
      long typeCode = readUnsigned(artifact, cursor + 4, 4);
      assert(name < moduleStringCount);
      assert(0 < typeCode);
      set(names, global, moduleStringBase + name);
      set(typeCodes, global, typeCode);
      set(lowValues, global, readUnsigned(artifact, cursor + 8, 4));
      set(highValues, global, readUnsigned(artifact, cursor + 12, 4));
      global += 1;
    }

    global = 0;
    while (global < globalCount) limit MAX_GLOBALS {
      long target = closureGlobalCount + global;
      set(closureGlobals, target, names[global]);
      set(closureGlobals, 4096 + target, typeCodes[global]);
      set(closureGlobals, 8192 + target, lowValues[global]);
      set(closureGlobals, 12288 + target, highValues[global]);
      set(closureGlobals, 16384 + target, moduleOwner);
      global += 1;
    }

    drop(highValues);
    drop(lowValues);
    drop(typeCodes);
    drop(names);
    drop(staging);
    return closureGlobalCount + globalCount;
  }
}
