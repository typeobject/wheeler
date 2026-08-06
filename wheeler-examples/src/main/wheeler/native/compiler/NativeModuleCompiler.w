//! Compiles one bounded framed scalar-constant module set with the Wheeler-native driver.

module examples.compiler.native_module_compiler;

import wheeler.compiler.driver;

classical class NativeModuleCompiler {
  private const long FRAME_LENGTH_WIDTH = 4;
  private const long NO_IMPORTED_MODULES = 0;
  private const long SINGLE_MODULE_COUNT = 1;
  private const long PAIR_MODULE_COUNT = 2;
  private const long TRIPLE_MODULE_COUNT = 3;
  private const long QUADRUPLE_MODULE_COUNT = 4;
  private const long QUINTUPLE_MODULE_COUNT = 5;
  private const long SEXTUPLE_MODULE_COUNT = 6;
  private const long SEPTUPLE_MODULE_COUNT = 7;
  private const long MAX_FRAME_SOURCE_BYTES = 16384;

  state long moduleCount = 0;
  state long importedLength = 0;
  state long secondImportedLength = 0;
  state long thirdImportedLength = 0;
  state long fourthImportedLength = 0;
  state long fifthImportedLength = 0;
  state long sixthImportedLength = 0;
  state long seventhImportedLength = 0;
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

  private void publishZero(borrow byteview input, borrow mut bytes output) {
    long rootStart = FRAME_LENGTH_WIDTH;
    rootLength = bufferLength(input) - rootStart;
    assert(0 < rootLength);
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, rootStart, rootBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimal(rootSource, output);
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(arena);
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

  private void publishThree(borrow byteview input, borrow mut bytes output) {
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
    long thirdLengthOffset = secondStart + secondImportedLength;
    assert(thirdLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    thirdImportedLength = framedLength(input, thirdLengthOffset);
    assert(0 < thirdImportedLength);
    assert(thirdImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long thirdStart = thirdLengthOffset + FRAME_LENGTH_WIDTH;
    long rootStart = thirdStart + thirdImportedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 65536, /* allocations= */ 4);
    bytes firstBytes = allocateBytes(arena, importedLength);
    bytes secondBytes = allocateBytes(arena, secondImportedLength);
    bytes thirdBytes = allocateBytes(arena, thirdImportedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, firstStart, firstBytes);
    copyFrame(input, secondStart, secondBytes);
    copyFrame(input, thirdStart, thirdBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 firstSource = freezeUtf8(firstBytes);
    utf8 secondSource = freezeUtf8(secondBytes);
    utf8 thirdSource = freezeUtf8(thirdBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithThreeConstantImports(
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      output
    );
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(thirdSource);
    drop(secondSource);
    drop(firstSource);
    drop(arena);
  }

  private void publishFour(borrow byteview input, borrow mut bytes output) {
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
    long thirdLengthOffset = secondStart + secondImportedLength;
    assert(thirdLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    thirdImportedLength = framedLength(input, thirdLengthOffset);
    assert(0 < thirdImportedLength);
    assert(thirdImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long thirdStart = thirdLengthOffset + FRAME_LENGTH_WIDTH;
    long fourthLengthOffset = thirdStart + thirdImportedLength;
    assert(fourthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    fourthImportedLength = framedLength(input, fourthLengthOffset);
    assert(0 < fourthImportedLength);
    assert(fourthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long fourthStart = fourthLengthOffset + FRAME_LENGTH_WIDTH;
    long rootStart = fourthStart + fourthImportedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 81920, /* allocations= */ 5);
    bytes firstBytes = allocateBytes(arena, importedLength);
    bytes secondBytes = allocateBytes(arena, secondImportedLength);
    bytes thirdBytes = allocateBytes(arena, thirdImportedLength);
    bytes fourthBytes = allocateBytes(arena, fourthImportedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, firstStart, firstBytes);
    copyFrame(input, secondStart, secondBytes);
    copyFrame(input, thirdStart, thirdBytes);
    copyFrame(input, fourthStart, fourthBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 firstSource = freezeUtf8(firstBytes);
    utf8 secondSource = freezeUtf8(secondBytes);
    utf8 thirdSource = freezeUtf8(thirdBytes);
    utf8 fourthSource = freezeUtf8(fourthBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithFourConstantImports(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(fourthSource);
    drop(thirdSource);
    drop(secondSource);
    drop(firstSource);
    drop(arena);
  }

  private void publishFive(borrow byteview input, borrow mut bytes output) {
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
    long thirdLengthOffset = secondStart + secondImportedLength;
    assert(thirdLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    thirdImportedLength = framedLength(input, thirdLengthOffset);
    assert(0 < thirdImportedLength);
    assert(thirdImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long thirdStart = thirdLengthOffset + FRAME_LENGTH_WIDTH;
    long fourthLengthOffset = thirdStart + thirdImportedLength;
    assert(fourthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    fourthImportedLength = framedLength(input, fourthLengthOffset);
    assert(0 < fourthImportedLength);
    assert(fourthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long fourthStart = fourthLengthOffset + FRAME_LENGTH_WIDTH;
    long fifthLengthOffset = fourthStart + fourthImportedLength;
    assert(fifthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    fifthImportedLength = framedLength(input, fifthLengthOffset);
    assert(0 < fifthImportedLength);
    assert(fifthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long fifthStart = fifthLengthOffset + FRAME_LENGTH_WIDTH;
    long rootStart = fifthStart + fifthImportedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 98304, /* allocations= */ 6);
    bytes firstBytes = allocateBytes(arena, importedLength);
    bytes secondBytes = allocateBytes(arena, secondImportedLength);
    bytes thirdBytes = allocateBytes(arena, thirdImportedLength);
    bytes fourthBytes = allocateBytes(arena, fourthImportedLength);
    bytes fifthBytes = allocateBytes(arena, fifthImportedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, firstStart, firstBytes);
    copyFrame(input, secondStart, secondBytes);
    copyFrame(input, thirdStart, thirdBytes);
    copyFrame(input, fourthStart, fourthBytes);
    copyFrame(input, fifthStart, fifthBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 firstSource = freezeUtf8(firstBytes);
    utf8 secondSource = freezeUtf8(secondBytes);
    utf8 thirdSource = freezeUtf8(thirdBytes);
    utf8 fourthSource = freezeUtf8(fourthBytes);
    utf8 fifthSource = freezeUtf8(fifthBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithFiveConstantImports(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(fifthSource);
    drop(fourthSource);
    drop(thirdSource);
    drop(secondSource);
    drop(firstSource);
    drop(arena);
  }

  private void publishSix(borrow byteview input, borrow mut bytes output) {
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
    long thirdLengthOffset = secondStart + secondImportedLength;
    assert(thirdLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    thirdImportedLength = framedLength(input, thirdLengthOffset);
    assert(0 < thirdImportedLength);
    assert(thirdImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long thirdStart = thirdLengthOffset + FRAME_LENGTH_WIDTH;
    long fourthLengthOffset = thirdStart + thirdImportedLength;
    assert(fourthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    fourthImportedLength = framedLength(input, fourthLengthOffset);
    assert(0 < fourthImportedLength);
    assert(fourthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long fourthStart = fourthLengthOffset + FRAME_LENGTH_WIDTH;
    long fifthLengthOffset = fourthStart + fourthImportedLength;
    assert(fifthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    fifthImportedLength = framedLength(input, fifthLengthOffset);
    assert(0 < fifthImportedLength);
    assert(fifthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long fifthStart = fifthLengthOffset + FRAME_LENGTH_WIDTH;
    long sixthLengthOffset = fifthStart + fifthImportedLength;
    assert(sixthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    sixthImportedLength = framedLength(input, sixthLengthOffset);
    assert(0 < sixthImportedLength);
    assert(sixthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long sixthStart = sixthLengthOffset + FRAME_LENGTH_WIDTH;
    long rootStart = sixthStart + sixthImportedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 114688, /* allocations= */ 7);
    bytes firstBytes = allocateBytes(arena, importedLength);
    bytes secondBytes = allocateBytes(arena, secondImportedLength);
    bytes thirdBytes = allocateBytes(arena, thirdImportedLength);
    bytes fourthBytes = allocateBytes(arena, fourthImportedLength);
    bytes fifthBytes = allocateBytes(arena, fifthImportedLength);
    bytes sixthBytes = allocateBytes(arena, sixthImportedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, firstStart, firstBytes);
    copyFrame(input, secondStart, secondBytes);
    copyFrame(input, thirdStart, thirdBytes);
    copyFrame(input, fourthStart, fourthBytes);
    copyFrame(input, fifthStart, fifthBytes);
    copyFrame(input, sixthStart, sixthBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 firstSource = freezeUtf8(firstBytes);
    utf8 secondSource = freezeUtf8(secondBytes);
    utf8 thirdSource = freezeUtf8(thirdBytes);
    utf8 fourthSource = freezeUtf8(fourthBytes);
    utf8 fifthSource = freezeUtf8(fifthBytes);
    utf8 sixthSource = freezeUtf8(sixthBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithSixConstantImports(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(sixthSource);
    drop(fifthSource);
    drop(fourthSource);
    drop(thirdSource);
    drop(secondSource);
    drop(firstSource);
    drop(arena);
  }

  private void publishSeven(borrow byteview input, borrow mut bytes output) {
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
    long thirdLengthOffset = secondStart + secondImportedLength;
    assert(thirdLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    thirdImportedLength = framedLength(input, thirdLengthOffset);
    assert(0 < thirdImportedLength);
    assert(thirdImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long thirdStart = thirdLengthOffset + FRAME_LENGTH_WIDTH;
    long fourthLengthOffset = thirdStart + thirdImportedLength;
    assert(fourthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    fourthImportedLength = framedLength(input, fourthLengthOffset);
    assert(0 < fourthImportedLength);
    assert(fourthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long fourthStart = fourthLengthOffset + FRAME_LENGTH_WIDTH;
    long fifthLengthOffset = fourthStart + fourthImportedLength;
    assert(fifthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    fifthImportedLength = framedLength(input, fifthLengthOffset);
    assert(0 < fifthImportedLength);
    assert(fifthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long fifthStart = fifthLengthOffset + FRAME_LENGTH_WIDTH;
    long sixthLengthOffset = fifthStart + fifthImportedLength;
    assert(sixthLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    sixthImportedLength = framedLength(input, sixthLengthOffset);
    assert(0 < sixthImportedLength);
    assert(sixthImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long sixthStart = sixthLengthOffset + FRAME_LENGTH_WIDTH;
    long seventhLengthOffset = sixthStart + sixthImportedLength;
    assert(seventhLengthOffset + FRAME_LENGTH_WIDTH < bufferLength(input));
    seventhImportedLength = framedLength(input, seventhLengthOffset);
    assert(0 < seventhImportedLength);
    assert(seventhImportedLength < MAX_FRAME_SOURCE_BYTES + 1);
    long seventhStart = seventhLengthOffset + FRAME_LENGTH_WIDTH;
    long rootStart = seventhStart + seventhImportedLength;
    assert(rootStart < bufferLength(input));
    rootLength = bufferLength(input) - rootStart;
    assert(rootLength < MAX_FRAME_SOURCE_BYTES + 1);

    region arena = new region(/* bytes= */ 131072, /* allocations= */ 8);
    bytes firstBytes = allocateBytes(arena, importedLength);
    bytes secondBytes = allocateBytes(arena, secondImportedLength);
    bytes thirdBytes = allocateBytes(arena, thirdImportedLength);
    bytes fourthBytes = allocateBytes(arena, fourthImportedLength);
    bytes fifthBytes = allocateBytes(arena, fifthImportedLength);
    bytes sixthBytes = allocateBytes(arena, sixthImportedLength);
    bytes seventhBytes = allocateBytes(arena, seventhImportedLength);
    bytes rootBytes = allocateBytes(arena, rootLength);
    copyFrame(input, firstStart, firstBytes);
    copyFrame(input, secondStart, secondBytes);
    copyFrame(input, thirdStart, thirdBytes);
    copyFrame(input, fourthStart, fourthBytes);
    copyFrame(input, fifthStart, fifthBytes);
    copyFrame(input, sixthStart, sixthBytes);
    copyFrame(input, seventhStart, seventhBytes);
    copyFrame(input, rootStart, rootBytes);
    utf8 firstSource = freezeUtf8(firstBytes);
    utf8 secondSource = freezeUtf8(secondBytes);
    utf8 thirdSource = freezeUtf8(thirdBytes);
    utf8 fourthSource = freezeUtf8(fourthBytes);
    utf8 fifthSource = freezeUtf8(fifthBytes);
    utf8 sixthSource = freezeUtf8(sixthBytes);
    utf8 seventhSource = freezeUtf8(seventhBytes);
    utf8 rootSource = freezeUtf8(rootBytes);
    Compilation compiled = compileMinimalWithSevenConstantImports(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource,
      output
    );
    artifactLength = compiled.length;
    published = 1;
    drop(rootSource);
    drop(seventhSource);
    drop(sixthSource);
    drop(fifthSource);
    drop(fourthSource);
    drop(thirdSource);
    drop(secondSource);
    drop(firstSource);
    drop(arena);
  }

  /// Compiles a canonical frame containing zero through seven imported modules.
  ///
  /// - Effects: Mutates fixture state and caller-owned byte output.
  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(FRAME_LENGTH_WIDTH < bufferLength(input));
    moduleCount = framedLength(input, 0);
    if (moduleCount == NO_IMPORTED_MODULES) {
      publishZero(input, output);
    } else {
      if (moduleCount == SINGLE_MODULE_COUNT) {
        publishOne(input, output);
      } else {
        if (moduleCount == PAIR_MODULE_COUNT) {
          publishTwo(input, output);
        } else {
          if (moduleCount == TRIPLE_MODULE_COUNT) {
            publishThree(input, output);
          } else {
            if (moduleCount == QUADRUPLE_MODULE_COUNT) {
              publishFour(input, output);
            } else {
              if (moduleCount == QUINTUPLE_MODULE_COUNT) {
                publishFive(input, output);
              } else {
                if (moduleCount == SEXTUPLE_MODULE_COUNT) {
                  publishSix(input, output);
                } else {
                  if (moduleCount == SEPTUPLE_MODULE_COUNT) {
                    publishSeven(input, output);
                  } else {
                    assert(published == 1);
                  }
                }
              }
            }
          }
        }
      }
    }

    assert(published == 1);
    setOutputLength(output, artifactLength);
  }
}
