//! Compiles one bounded framed scalar-constant module set with the Wheeler-native driver.

module examples.compiler.native_module_compiler;

import wheeler.compiler.driver;

classical class NativeModuleCompiler {
  private const long FRAME_LENGTH_WIDTH = 4;
  private const long SINGLE_MODULE_COUNT = 1;
  private const long PAIR_MODULE_COUNT = 2;
  private const long MAX_FRAME_SOURCE_BYTES = 16384;

  state long moduleCount = 0;
  state long importedLength = 0;
  state long secondImportedLength = 0;
  state long rootLength = 0;
  state long artifactLength = 0;
  state long published = 0;

  private long framedLength(borrow byteview input, long offset) {
    long value = input[offset];
    long multiplier = 256;
    long cursor = 1;
    while (cursor < FRAME_LENGTH_WIDTH) limit FRAME_LENGTH_WIDTH {
      value += input[offset + cursor] * multiplier;
      multiplier = multiplier * 256;
      cursor += 1;
    }

    return value;
  }

  private void copyFrame(borrow byteview input, long inputStart, borrow mut bytes output) {
    long cursor = 0;
    while (cursor < bufferLength(output)) limit MAX_FRAME_SOURCE_BYTES {
      setByte(output, cursor, input[inputStart + cursor]);
      cursor += 1;
    }
  }

  private void publishOne(borrow byteview input, borrow mut bytes output) {
    long firstLengthOffset = FRAME_LENGTH_WIDTH;
    long firstStart = firstLengthOffset + FRAME_LENGTH_WIDTH;
    importedLength = framedLength(input, firstLengthOffset);
    assert(0 < importedLength);
    assert(importedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long rootStart = firstStart + importedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 32768, /* allocations= */ 2);
    bytes importedBytes = allocateBytes(arena, importedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, firstStart, importedBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 importedSource = freezeUtf8(importedBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithConstantImport(importedSource, rootSource, output);
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(importedSource);
    drop(arena);
  }

  private void publishTwo(borrow byteview input, borrow mut bytes output) {
    long firstLengthOffset = FRAME_LENGTH_WIDTH;
    long firstStart = firstLengthOffset + FRAME_LENGTH_WIDTH;
    importedLength = framedLength(input, firstLengthOffset);
    assert(0 < importedLength);
    assert(importedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long secondLengthOffset = firstStart + importedLength;
    assert(secondLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    secondImportedLength = framedLength(input, secondLengthOffset);
    assert(0 < secondImportedLength);
    assert(secondImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long secondStart = secondLengthOffset + FRAME_LENGTH_WIDTH;
    long rootStart = secondStart + secondImportedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 49152, /* allocations= */ 3);
    bytes firstBytes = allocateBytes(arena, importedLength);
    bytes secondBytes = allocateBytes(arena, secondImportedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, firstStart, firstBytes);
    copyFrame(input, secondStart, secondBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 firstSource = freezeUtf8(firstBytes);
    utf8 secondSource = freezeUtf8(secondBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithConstantImports(
      firstSource,
      secondSource,
      rootSource,
      output
    );
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(secondSource);
    drop(firstSource);
    drop(arena);
  }

  /// Compiles a one- or two-module canonical length-framed source set.
  ///
  /// - Effects: Mutates fixture state and caller-owned byte output.
  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(FRAME_LENGTH_WIDTH < bufferLength(input));
    moduleCount = framedLength(input, 0);
    if (moduleCount == SINGLE_MODULE_COUNT) {
      publishOne(input, output);
    } else {
      if (moduleCount == PAIR_MODULE_COUNT) {
        publishTwo(input, output);
      } else {
        assert(published == 1);
      }
    }

    assert(published == 1);
    setOutputLength(output, artifactLength);
  }
}
