//! Compiles one framed direct public-constant import with the Wheeler-native driver.

module examples.compiler.native_module_compiler;

import wheeler.compiler.driver;

classical class NativeModuleCompiler {
  private const long FRAME_LENGTH_WIDTH = 4;
  private const long MAX_FRAME_SOURCE_BYTES = 16384;

  state long importedLength = 0;
  state long rootLength = 0;
  state long artifactLength = 0;
  state long published = 0;

  private long framedLength(borrow byteview input) {
    long value = input[0];
    long multiplier = 256;
    long cursor = 1;
    while (cursor < FRAME_LENGTH_WIDTH) limit FRAME_LENGTH_WIDTH {
      value += input[cursor] * multiplier;
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

  /// Compiles one canonical `u32 imported_length`, imported source, and root source frame.
  ///
  /// - Effects: Mutates fixture state and caller-owned byte output.
  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(FRAME_LENGTH_WIDTH < bufferLength(input));
    importedLength = framedLength(input);
    assert(0 < importedLength);
    assert(importedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long rootStart = FRAME_LENGTH_WIDTH + importedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 32768, /* allocations= */ 2);
    bytes importedBytes = allocateBytes(arena, importedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, FRAME_LENGTH_WIDTH, importedBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 importedSource = freezeUtf8(importedBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithPublicConstantImport(
      importedSource,
      rootSource,
      output
    );
    artifactLength = compiled.length;
    published = 1;
    setOutputLength(output, compiled.length);
    drop(rootSource);
    drop(importedSource);
    drop(arena);
  }
}
