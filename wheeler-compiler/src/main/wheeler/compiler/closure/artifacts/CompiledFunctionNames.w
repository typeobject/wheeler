//! Retains source-local function names as counted closure string references.

module wheeler.compiler.closure.compiled_function_names;

import wheeler.core.encoding.binary;

classical class CompiledFunctionNames {
  private const long MAX_FUNCTIONS = 4096;
  private const long MAX_SECTIONS = 64;
  private const long MAX_STRINGS = 16384;
  private const long STAGING_BYTES = 32768;

  private long functionSectionStart(borrow byteview artifact, long artifactLength) {
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
    long selected = -1;
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      long directory = 40 + section * 32;
      long type = readUnsigned(artifact, directory, 4);
      long start = readUnsigned(artifact, directory + 8, 8);
      long length = readUnsigned(artifact, directory + 16, 8);
      assert(previousType < type);
      assert(readUnsigned(artifact, directory + 4, 4) == 1);
      assert(readUnsigned(artifact, directory + 24, 4) == 8);
      assert(readUnsigned(artifact, directory + 28, 4) == 0);
      assert(start % 8 == 0);
      assert(previousEnd < start + 1);
      assert(start < artifactLength + 1);
      assert(length < artifactLength - start + 1);
      previousType = type;
      previousEnd = start + length;
      if (type == 5) {
        selected = start;
      }

      section += 1;
    }

    assert(-1 < selected);
    return selected;
  }

  /// Appends exact descriptor names into an already assigned function window.
  public void appendCompiledFunctionNames(
    borrow byteview artifact,
    long artifactLength,
    long moduleStringBase,
    long moduleStringCount,
    long firstFunction,
    long expectedFunctionCount,
    borrow mut words closureFunctionNameRows
  ) {
    assert(-1 < moduleStringBase);
    assert(-1 < moduleStringCount);
    assert(moduleStringCount < MAX_STRINGS + 1);
    assert(-1 < firstFunction);
    assert(firstFunction < MAX_FUNCTIONS + 1);
    assert(0 < expectedFunctionCount);
    assert(expectedFunctionCount < MAX_FUNCTIONS - firstFunction + 1);
    assert(bufferLength(closureFunctionNameRows) == MAX_FUNCTIONS);
    long sectionStart = functionSectionStart(artifact, artifactLength);
    long functionCount = readUnsigned(artifact, sectionStart, 4);
    assert(functionCount == expectedFunctionCount);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 1);
    words stagedNames = allocate(staging, MAX_FUNCTIONS);
    long function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      long descriptor = sectionStart + 4 + function * 40;
      assert(descriptor < artifactLength + 1);
      assert(40 < artifactLength - descriptor + 1);
      assert(readUnsigned(artifact, descriptor, 4) == function);
      long name = readUnsigned(artifact, descriptor + 4, 4);
      assert(name < moduleStringCount);
      set(stagedNames, function, moduleStringBase + name);
      function += 1;
    }

    function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      set(closureFunctionNameRows, firstFunction + function, stagedNames[function]);
      function += 1;
    }

    drop(stagedNames);
    drop(staging);
  }

  /// Maps closure string references to final canonical string IDs atomically.
  public void resolveLinkedFunctionNameIds(
    long functionCount,
    long closureStringCount,
    borrow mut words closureFunctionNameRows,
    borrow mut words finalStringRows,
    borrow mut words finalFunctionNameIds
  ) {
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(-1 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(bufferLength(closureFunctionNameRows) == MAX_FUNCTIONS);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(bufferLength(finalFunctionNameIds) == MAX_FUNCTIONS);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 1);
    words stagedIds = allocate(staging, MAX_FUNCTIONS);
    long function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      long sourceName = closureFunctionNameRows[function];
      assert(-1 < sourceName);
      assert(sourceName < closureStringCount);
      long finalName = finalStringRows[sourceName];
      assert(-1 < finalName);
      assert(finalName < closureStringCount);
      set(stagedIds, function, finalName);
      function += 1;
    }

    function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      set(finalFunctionNameIds, function, stagedIds[function]);
      function += 1;
    }

    drop(stagedIds);
    drop(staging);
  }
}
