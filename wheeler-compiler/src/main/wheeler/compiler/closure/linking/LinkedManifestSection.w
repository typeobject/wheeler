//! Emits one canonical root manifest from counted string and function products.

module wheeler.compiler.closure.linked_manifest_section;

import wheeler.core.encoding.binary;

classical class LinkedManifestSection {
  private const long MANIFEST_BYTES = 24;
  private const long MAX_FUNCTIONS = 4096;
  private const long MAX_MODULES = 512;
  private const long MAX_SECTIONS = 64;
  private const long MAX_STRINGS = 16384;

  private void writeUnsigned(borrow mut bytes output, long cursor, long width, long value) {
    assert(-1 < value);
    long remaining = value;
    long outputByte = 0;
    while (outputByte < width) limit 4 {
      setByte(output, cursor + outputByte, remaining % 256);
      remaining = remaining / 256;
      outputByte += 1;
    }

    assert(remaining == 0);
  }

  private long manifestStart(borrow byteview artifact, long artifactLength) {
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
      if (type == 1) {
        assert(length == MANIFEST_BYTES);
        selected = start;
      }

      section += 1;
    }

    assert(-1 < selected);
    return selected;
  }

  /// Emits section type 1 after resolving root-local name and entry IDs.
  public long emitLinkedManifestSection(
    borrow byteview rootArtifact,
    long artifactLength,
    long rootModule,
    long rootStringBase,
    long rootStringCount,
    long closureStringCount,
    borrow mut words finalStringRows,
    borrow mut words moduleFirstFunctions,
    borrow mut words moduleFunctionCounts,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < rootModule);
    assert(rootModule < MAX_MODULES);
    assert(-1 < rootStringBase);
    assert(-1 < rootStringCount);
    assert(-1 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(bufferLength(moduleFirstFunctions) == MAX_MODULES);
    assert(bufferLength(moduleFunctionCounts) == MAX_MODULES);
    assert(-1 < outputStart);
    assert(outputStart < bufferLength(output) + 1);
    assert(MANIFEST_BYTES < bufferLength(output) - outputStart + 1);
    long sourceStart = manifestStart(rootArtifact, artifactLength);
    long sourceName = readUnsigned(rootArtifact, sourceStart, 4);
    assert(sourceName < rootStringCount);
    long closureName = rootStringBase + sourceName;
    assert(closureName < closureStringCount);
    long finalName = finalStringRows[closureName];
    assert(-1 < finalName);
    assert(finalName < closureStringCount);
    long sourceEntry = readUnsigned(rootArtifact, sourceStart + 4, 4);
    long finalEntry = 4294967295;
    if (sourceEntry != 4294967295) {
      assert(sourceEntry < moduleFunctionCounts[rootModule]);
      finalEntry = moduleFirstFunctions[rootModule] + sourceEntry;
      assert(finalEntry < MAX_FUNCTIONS);
    }

    long maxHistory = readUnsigned(rootArtifact, sourceStart + 8, 4);
    long kind = readUnsigned(rootArtifact, sourceStart + 12, 4);
    assert(kind < 3);
    long maxStepsLow = readUnsigned(rootArtifact, sourceStart + 16, 4);
    long maxStepsHigh = readUnsigned(rootArtifact, sourceStart + 20, 4);

    writeUnsigned(output, outputStart, 4, finalName);
    writeUnsigned(output, outputStart + 4, 4, finalEntry);
    writeUnsigned(output, outputStart + 8, 4, maxHistory);
    writeUnsigned(output, outputStart + 12, 4, kind);
    writeUnsigned(output, outputStart + 16, 4, maxStepsLow);
    writeUnsigned(output, outputStart + 20, 4, maxStepsHigh);
    return MANIFEST_BYTES;
  }
}
