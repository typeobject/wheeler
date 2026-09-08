//! Emits one canonical root manifest from counted string and function products.

module wheeler.compiler.closure.linked_manifest_section;

import wheeler.core.encoding.binary;

classical class LinkedManifestSection {
  private const long MANIFEST_BYTES = 24;
  private const long MAX_FUNCTIONS = 4096;
  private const long MAX_MODULES = 512;
  private const long MAX_SECTIONS = 64;
  private const long MAX_STRINGS = 16384;
  private const long UNSIGNED_WORD_LIMIT = 4294967296;

  /// Retains manifest facts without an artifact view. Entry -1 denotes no classical entry.
  /// Name and entry coordinates belong to the source module until final binding.
  public record ModuleManifestProduct(
    long nameString,
    long entryFunction,
    long maxHistory,
    long kind,
    long maxStepsLow,
    long maxStepsHigh
  ) {}

  private void requireManifestFields(ModuleManifestProduct manifest) {
    assert(-1 < manifest.nameString);
    assert(manifest.nameString < MAX_STRINGS);
    assert(-2 < manifest.entryFunction);
    assert(manifest.entryFunction < MAX_FUNCTIONS);
    assert(-1 < manifest.maxHistory);
    assert(manifest.maxHistory < UNSIGNED_WORD_LIMIT);
    assert(-1 < manifest.kind);
    assert(manifest.kind < 3);
    assert(-1 < manifest.maxStepsLow);
    assert(manifest.maxStepsLow < UNSIGNED_WORD_LIMIT);
    assert(-1 < manifest.maxStepsHigh);
    assert(manifest.maxStepsHigh < UNSIGNED_WORD_LIMIT);
  }

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
    assert(artifactLength < bufferLength(artifact) + 1);
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
    assert(previousEnd < artifactLength + 1);
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

  /// Copies a structurally indexed manifest into an immutable product before artifact release.
  /// Executable limits and entry semantics remain the artifact verifier's responsibility.
  public ModuleManifestProduct readCompiledModuleManifest(
    borrow byteview artifact,
    long artifactLength
  ) {
    long start = manifestStart(artifact, artifactLength);
    long entry = readUnsigned(artifact, start + 4, 4);
    if (entry == UNSIGNED_WORD_LIMIT - 1) {
      entry = -1;
    }

    ModuleManifestProduct manifest = new ModuleManifestProduct(
      readUnsigned(artifact, start, 4),
      entry,
      readUnsigned(artifact, start + 8, 4),
      readUnsigned(artifact, start + 12, 4),
      readUnsigned(artifact, start + 16, 4),
      readUnsigned(artifact, start + 20, 4)
    );
    requireManifestFields(manifest);
    return manifest;
  }

  /// Writes all six manifest words after checking every field and the complete output window.
  /// Coordinates must already belong to the destination artifact. This encodes, not verifies.
  public long writeModuleManifestProduct(
    ModuleManifestProduct manifest,
    borrow mut bytes output,
    long outputStart
  ) {
    requireManifestFields(manifest);
    assert(-1 < outputStart);
    assert(outputStart < bufferLength(output) + 1);
    assert(MANIFEST_BYTES < bufferLength(output) - outputStart + 1);
    long entry = manifest.entryFunction;
    if (entry == -1) {
      entry = UNSIGNED_WORD_LIMIT - 1;
    }

    writeUnsigned(output, outputStart, 4, manifest.nameString);
    writeUnsigned(output, outputStart + 4, 4, entry);
    writeUnsigned(output, outputStart + 8, 4, manifest.maxHistory);
    writeUnsigned(output, outputStart + 12, 4, manifest.kind);
    writeUnsigned(output, outputStart + 16, 4, manifest.maxStepsLow);
    writeUnsigned(output, outputStart + 20, 4, manifest.maxStepsHigh);
    return MANIFEST_BYTES;
  }

  /// Binds a closed root manifest to final string and function IDs, then emits section type 1.
  public long emitLinkedManifestSection(
    ModuleManifestProduct manifest,
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
    requireManifestFields(manifest);
    assert(-1 < rootModule);
    assert(rootModule < MAX_MODULES);
    assert(-1 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(-1 < rootStringBase);
    assert(rootStringBase < closureStringCount + 1);
    assert(-1 < rootStringCount);
    assert(rootStringCount < closureStringCount - rootStringBase + 1);
    assert(bufferLength(finalStringRows) == MAX_STRINGS);
    assert(bufferLength(moduleFirstFunctions) == MAX_MODULES);
    assert(bufferLength(moduleFunctionCounts) == MAX_MODULES);
    assert(manifest.nameString < rootStringCount);
    long closureName = rootStringBase + manifest.nameString;
    long finalName = finalStringRows[closureName];
    assert(-1 < finalName);
    assert(finalName < closureStringCount);
    long firstFunction = moduleFirstFunctions[rootModule];
    long functionCount = moduleFunctionCounts[rootModule];
    assert(-1 < firstFunction);
    assert(firstFunction < MAX_FUNCTIONS + 1);
    assert(-1 < functionCount);
    assert(functionCount < MAX_FUNCTIONS - firstFunction + 1);
    long finalEntry = -1;
    if (-1 < manifest.entryFunction) {
      assert(manifest.entryFunction < functionCount);
      finalEntry = firstFunction + manifest.entryFunction;
    }

    ModuleManifestProduct linked = new ModuleManifestProduct(
      finalName,
      finalEntry,
      manifest.maxHistory,
      manifest.kind,
      manifest.maxStepsLow,
      manifest.maxStepsHigh
    );
    return writeModuleManifestProduct(linked, output, outputStart);
  }
}
