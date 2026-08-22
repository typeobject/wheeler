//! Compiles a previously validated bounded target-source plan.

module wheeler.runtime.testing.runners.test_source_compilation;

import wheeler.compiler.driver;
import wheeler.runtime.testing.runners.test_source_plan;
import wheeler.runtime.testing.runners.test_source_tests;

classical class TestSourceCompilation {
  private const long MAX_COMPILED_SOURCES = 8;
  private const long MAX_LOWERED_PLAN_BYTES = 32772;
  private const long MAX_TEST_SOURCE_BYTES = 4096;
  private const long TEST_ARTIFACT_BYTES = 32768;

  private long copyRange(
    borrow byteview input,
    long inputStart,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long offset = 0;
    while (offset < length) limit MAX_LOWERED_PLAN_BYTES {
      setByte(output, outputStart + offset, input[inputStart + offset]);
      offset += 1;
    }

    return outputStart + length;
  }

  private void writeUnsigned32BigEndian(borrow mut bytes output, long start, long value) {
    setByte(output, start, value / 16777216 % 256);
    setByte(output, start + 1, value / 65536 % 256);
    setByte(output, start + 2, value / 256 % 256);
    setByte(output, start + 3, value % 256);
  }

  private long checkedLength(Compilation compiled) {
    assert(0 < compiled.length);
    assert(compiled.length < TEST_ARTIFACT_BYTES + 1);
    return compiled.length;
  }

  private utf8 sourceAt(
    borrow byteview input,
    long start,
    long length,
    long ordinal,
    borrow mut region arena
  ) {
    long sourceLength = validatedSourceLength(input, start, length, ordinal);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    copyValidatedSource(input, start, length, ordinal, sourceBytes);
    return freezeUtf8(sourceBytes);
  }

  /// Checks compiler source-count and per-source byte bounds after plan validation.
  public boolean validCompilableSourcePlan(borrow byteview input, long start, long length) {
    long sourceCount = validatedSourceCount(input, start, length);
    if (sourceCount == 0) {
      return false;
    }

    if (MAX_COMPILED_SOURCES < sourceCount) {
      return false;
    }

    long source = 0;
    while (source < sourceCount) limit MAX_COMPILED_SOURCES {
      long sourceLength = validatedSourceLength(input, start, length, source);
      if (MAX_TEST_SOURCE_BYTES < sourceLength) {
        return false;
      }

      source += 1;
    }

    return true;
  }

  /// Compiles one discovered parameterless root test as a direct native entry.
  public long compileValidatedParameterlessTest(
    borrow byteview input,
    long start,
    long length,
    long rootOrdinal,
    borrow byteview selectedName,
    long selectedNameStart,
    long selectedNameLength,
    long testCount,
    borrow mut bytes artifact
  ) {
    assert(validCompilableSourcePlan(input, start, length));
    assert(rootOrdinal < validatedSourceCount(input, start, length));
    assert(bufferLength(artifact) == TEST_ARTIFACT_BYTES);
    long sourceLength = validatedSourceLength(input, start, length, rootOrdinal);
    long sourceStart = validatedSourceStart(input, start, length, rootOrdinal);
    long loweredSourceLength = sourceLength + 5 - selectedNameLength;
    long loweredPlanLength = length + loweredSourceLength - sourceLength;
    assert(loweredPlanLength < MAX_LOWERED_PLAN_BYTES + 1);
    region lowering = new region(/* bytes= */ 36873, /* allocations= */ 2);
    bytes entryBytes = allocateBytes(lowering, loweredSourceLength);
    copyParameterlessEntrySource(
      input,
      start,
      length,
      rootOrdinal,
      selectedName,
      selectedNameStart,
      selectedNameLength,
      testCount,
      entryBytes
    );
    bytes plan = allocateBytes(lowering, loweredPlanLength);
    long sourceLengthOffset = sourceStart - 4;
    long cursor = copyRange(
      input,
      start,
      sourceLengthOffset - start,
      plan,
      /* outputStart= */ 0
    );
    writeUnsigned32BigEndian(plan, cursor, loweredSourceLength);
    cursor += 4;
    cursor = copyRange(entryBytes, /* inputStart= */ 0, loweredSourceLength, plan, cursor);
    long sourceEnd = sourceStart + sourceLength;
    cursor = copyRange(input, sourceEnd, start + length - sourceEnd, plan, cursor);
    assert(cursor == loweredPlanLength);
    long artifactLength = compileValidatedSourcePlan(
      plan,
      /* start= */ 0,
      loweredPlanLength,
      rootOrdinal,
      artifact
    );
    drop(plan);
    drop(entryBytes);
    drop(lowering);
    return artifactLength;
  }

  /// Compiles one validated one-to-eight-source plan into recovery storage.
  public long compileValidatedSourcePlan(
    borrow byteview input,
    long start,
    long length,
    long rootOrdinal,
    borrow mut bytes artifact
  ) {
    assert(validCompilableSourcePlan(input, start, length));
    assert(bufferLength(artifact) == TEST_ARTIFACT_BYTES);
    long sourceCount = validatedSourceCount(input, start, length);
    assert(rootOrdinal < sourceCount);
    region sources = new region(/* bytes= */ 32768, /* allocations= */ 8);
    long artifactLength = 0;

    if (sourceCount == 1) {
      utf8 singleRoot = sourceAt(input, start, length, rootOrdinal, sources);
      artifactLength = checkedLength(compileMinimal(singleRoot, artifact));
      drop(singleRoot);
    }

    if (sourceCount == 2) {
      long importedOrdinal = 1 - rootOrdinal;
      utf8 imported = sourceAt(input, start, length, importedOrdinal, sources);
      utf8 importedRoot = sourceAt(input, start, length, rootOrdinal, sources);
      artifactLength = checkedLength(
        compileMinimalWithConstantImport(imported, importedRoot, artifact)
      );
      drop(importedRoot);
      drop(imported);
    }

    if (sourceCount == 3) {
      utf8 first = sourceAt(input, start, length, /* ordinal= */ 0, sources);
      utf8 second = sourceAt(input, start, length, /* ordinal= */ 1, sources);
      utf8 third = sourceAt(input, start, length, /* ordinal= */ 2, sources);
      if (rootOrdinal == 0) {
        artifactLength = checkedLength(
          compileMinimalWithConstantImports(second, third, first, artifact)
        );
      }

      if (rootOrdinal == 1) {
        artifactLength = checkedLength(
          compileMinimalWithConstantImports(first, third, second, artifact)
        );
      }

      if (rootOrdinal == 2) {
        artifactLength = checkedLength(
          compileMinimalWithConstantImports(first, second, third, artifact)
        );
      }

      drop(third);
      drop(second);
      drop(first);
    }

    if (sourceCount == 4) {
      utf8 fourFirst = sourceAt(input, start, length, /* ordinal= */ 0, sources);
      utf8 fourSecond = sourceAt(input, start, length, /* ordinal= */ 1, sources);
      utf8 fourThird = sourceAt(input, start, length, /* ordinal= */ 2, sources);
      utf8 fourFourth = sourceAt(input, start, length, /* ordinal= */ 3, sources);
      if (rootOrdinal == 0) {
        artifactLength = checkedLength(
          compileMinimalWithThreeConstantImports(
            fourSecond,
            fourThird,
            fourFourth,
            fourFirst,
            artifact
          )
        );
      }

      if (rootOrdinal == 1) {
        artifactLength = checkedLength(
          compileMinimalWithThreeConstantImports(
            fourFirst,
            fourThird,
            fourFourth,
            fourSecond,
            artifact
          )
        );
      }

      if (rootOrdinal == 2) {
        artifactLength = checkedLength(
          compileMinimalWithThreeConstantImports(
            fourFirst,
            fourSecond,
            fourFourth,
            fourThird,
            artifact
          )
        );
      }

      if (rootOrdinal == 3) {
        artifactLength = checkedLength(
          compileMinimalWithThreeConstantImports(
            fourFirst,
            fourSecond,
            fourThird,
            fourFourth,
            artifact
          )
        );
      }

      drop(fourFourth);
      drop(fourThird);
      drop(fourSecond);
      drop(fourFirst);
    }

    if (sourceCount == 5) {
      utf8 fiveFirst = sourceAt(input, start, length, /* ordinal= */ 0, sources);
      utf8 fiveSecond = sourceAt(input, start, length, /* ordinal= */ 1, sources);
      utf8 fiveThird = sourceAt(input, start, length, /* ordinal= */ 2, sources);
      utf8 fiveFourth = sourceAt(input, start, length, /* ordinal= */ 3, sources);
      utf8 fiveFifth = sourceAt(input, start, length, /* ordinal= */ 4, sources);
      if (rootOrdinal == 0) {
        artifactLength = checkedLength(
          compileMinimalWithFourConstantImports(
            fiveSecond,
            fiveThird,
            fiveFourth,
            fiveFifth,
            fiveFirst,
            artifact
          )
        );
      }

      if (rootOrdinal == 1) {
        artifactLength = checkedLength(
          compileMinimalWithFourConstantImports(
            fiveFirst,
            fiveThird,
            fiveFourth,
            fiveFifth,
            fiveSecond,
            artifact
          )
        );
      }

      if (rootOrdinal == 2) {
        artifactLength = checkedLength(
          compileMinimalWithFourConstantImports(
            fiveFirst,
            fiveSecond,
            fiveFourth,
            fiveFifth,
            fiveThird,
            artifact
          )
        );
      }

      if (rootOrdinal == 3) {
        artifactLength = checkedLength(
          compileMinimalWithFourConstantImports(
            fiveFirst,
            fiveSecond,
            fiveThird,
            fiveFifth,
            fiveFourth,
            artifact
          )
        );
      }

      if (rootOrdinal == 4) {
        artifactLength = checkedLength(
          compileMinimalWithFourConstantImports(
            fiveFirst,
            fiveSecond,
            fiveThird,
            fiveFourth,
            fiveFifth,
            artifact
          )
        );
      }

      drop(fiveFifth);
      drop(fiveFourth);
      drop(fiveThird);
      drop(fiveSecond);
      drop(fiveFirst);
    }

    if (sourceCount == 6) {
      utf8 sixFirst = sourceAt(input, start, length, /* ordinal= */ 0, sources);
      utf8 sixSecond = sourceAt(input, start, length, /* ordinal= */ 1, sources);
      utf8 sixThird = sourceAt(input, start, length, /* ordinal= */ 2, sources);
      utf8 sixFourth = sourceAt(input, start, length, /* ordinal= */ 3, sources);
      utf8 sixFifth = sourceAt(input, start, length, /* ordinal= */ 4, sources);
      utf8 sixSixth = sourceAt(input, start, length, /* ordinal= */ 5, sources);
      if (rootOrdinal == 0) {
        artifactLength = checkedLength(
          compileMinimalWithFiveConstantImports(
            sixSecond,
            sixThird,
            sixFourth,
            sixFifth,
            sixSixth,
            sixFirst,
            artifact
          )
        );
      }

      if (rootOrdinal == 1) {
        artifactLength = checkedLength(
          compileMinimalWithFiveConstantImports(
            sixFirst,
            sixThird,
            sixFourth,
            sixFifth,
            sixSixth,
            sixSecond,
            artifact
          )
        );
      }

      if (rootOrdinal == 2) {
        artifactLength = checkedLength(
          compileMinimalWithFiveConstantImports(
            sixFirst,
            sixSecond,
            sixFourth,
            sixFifth,
            sixSixth,
            sixThird,
            artifact
          )
        );
      }

      if (rootOrdinal == 3) {
        artifactLength = checkedLength(
          compileMinimalWithFiveConstantImports(
            sixFirst,
            sixSecond,
            sixThird,
            sixFifth,
            sixSixth,
            sixFourth,
            artifact
          )
        );
      }

      if (rootOrdinal == 4) {
        artifactLength = checkedLength(
          compileMinimalWithFiveConstantImports(
            sixFirst,
            sixSecond,
            sixThird,
            sixFourth,
            sixSixth,
            sixFifth,
            artifact
          )
        );
      }

      if (rootOrdinal == 5) {
        artifactLength = checkedLength(
          compileMinimalWithFiveConstantImports(
            sixFirst,
            sixSecond,
            sixThird,
            sixFourth,
            sixFifth,
            sixSixth,
            artifact
          )
        );
      }

      drop(sixSixth);
      drop(sixFifth);
      drop(sixFourth);
      drop(sixThird);
      drop(sixSecond);
      drop(sixFirst);
    }

    if (sourceCount == 7) {
      utf8 sevenFirst = sourceAt(input, start, length, /* ordinal= */ 0, sources);
      utf8 sevenSecond = sourceAt(input, start, length, /* ordinal= */ 1, sources);
      utf8 sevenThird = sourceAt(input, start, length, /* ordinal= */ 2, sources);
      utf8 sevenFourth = sourceAt(input, start, length, /* ordinal= */ 3, sources);
      utf8 sevenFifth = sourceAt(input, start, length, /* ordinal= */ 4, sources);
      utf8 sevenSixth = sourceAt(input, start, length, /* ordinal= */ 5, sources);
      utf8 sevenSeventh = sourceAt(input, start, length, /* ordinal= */ 6, sources);
      if (rootOrdinal == 0) {
        artifactLength = checkedLength(
          compileMinimalWithSixConstantImports(
            sevenSecond,
            sevenThird,
            sevenFourth,
            sevenFifth,
            sevenSixth,
            sevenSeventh,
            sevenFirst,
            artifact
          )
        );
      }

      if (rootOrdinal == 1) {
        artifactLength = checkedLength(
          compileMinimalWithSixConstantImports(
            sevenFirst,
            sevenThird,
            sevenFourth,
            sevenFifth,
            sevenSixth,
            sevenSeventh,
            sevenSecond,
            artifact
          )
        );
      }

      if (rootOrdinal == 2) {
        artifactLength = checkedLength(
          compileMinimalWithSixConstantImports(
            sevenFirst,
            sevenSecond,
            sevenFourth,
            sevenFifth,
            sevenSixth,
            sevenSeventh,
            sevenThird,
            artifact
          )
        );
      }

      if (rootOrdinal == 3) {
        artifactLength = checkedLength(
          compileMinimalWithSixConstantImports(
            sevenFirst,
            sevenSecond,
            sevenThird,
            sevenFifth,
            sevenSixth,
            sevenSeventh,
            sevenFourth,
            artifact
          )
        );
      }

      if (rootOrdinal == 4) {
        artifactLength = checkedLength(
          compileMinimalWithSixConstantImports(
            sevenFirst,
            sevenSecond,
            sevenThird,
            sevenFourth,
            sevenSixth,
            sevenSeventh,
            sevenFifth,
            artifact
          )
        );
      }

      if (rootOrdinal == 5) {
        artifactLength = checkedLength(
          compileMinimalWithSixConstantImports(
            sevenFirst,
            sevenSecond,
            sevenThird,
            sevenFourth,
            sevenFifth,
            sevenSeventh,
            sevenSixth,
            artifact
          )
        );
      }

      if (rootOrdinal == 6) {
        artifactLength = checkedLength(
          compileMinimalWithSixConstantImports(
            sevenFirst,
            sevenSecond,
            sevenThird,
            sevenFourth,
            sevenFifth,
            sevenSixth,
            sevenSeventh,
            artifact
          )
        );
      }

      drop(sevenSeventh);
      drop(sevenSixth);
      drop(sevenFifth);
      drop(sevenFourth);
      drop(sevenThird);
      drop(sevenSecond);
      drop(sevenFirst);
    }

    if (sourceCount == 8) {
      utf8 eightFirst = sourceAt(input, start, length, /* ordinal= */ 0, sources);
      utf8 eightSecond = sourceAt(input, start, length, /* ordinal= */ 1, sources);
      utf8 eightThird = sourceAt(input, start, length, /* ordinal= */ 2, sources);
      utf8 eightFourth = sourceAt(input, start, length, /* ordinal= */ 3, sources);
      utf8 eightFifth = sourceAt(input, start, length, /* ordinal= */ 4, sources);
      utf8 eightSixth = sourceAt(input, start, length, /* ordinal= */ 5, sources);
      utf8 eightSeventh = sourceAt(input, start, length, /* ordinal= */ 6, sources);
      utf8 eightEighth = sourceAt(input, start, length, /* ordinal= */ 7, sources);
      if (rootOrdinal == 0) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightSecond,
            eightThird,
            eightFourth,
            eightFifth,
            eightSixth,
            eightSeventh,
            eightEighth,
            eightFirst,
            artifact
          )
        );
      }

      if (rootOrdinal == 1) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightFirst,
            eightThird,
            eightFourth,
            eightFifth,
            eightSixth,
            eightSeventh,
            eightEighth,
            eightSecond,
            artifact
          )
        );
      }

      if (rootOrdinal == 2) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightFirst,
            eightSecond,
            eightFourth,
            eightFifth,
            eightSixth,
            eightSeventh,
            eightEighth,
            eightThird,
            artifact
          )
        );
      }

      if (rootOrdinal == 3) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightFirst,
            eightSecond,
            eightThird,
            eightFifth,
            eightSixth,
            eightSeventh,
            eightEighth,
            eightFourth,
            artifact
          )
        );
      }

      if (rootOrdinal == 4) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightFirst,
            eightSecond,
            eightThird,
            eightFourth,
            eightSixth,
            eightSeventh,
            eightEighth,
            eightFifth,
            artifact
          )
        );
      }

      if (rootOrdinal == 5) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightFirst,
            eightSecond,
            eightThird,
            eightFourth,
            eightFifth,
            eightSeventh,
            eightEighth,
            eightSixth,
            artifact
          )
        );
      }

      if (rootOrdinal == 6) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightFirst,
            eightSecond,
            eightThird,
            eightFourth,
            eightFifth,
            eightSixth,
            eightEighth,
            eightSeventh,
            artifact
          )
        );
      }

      if (rootOrdinal == 7) {
        artifactLength = checkedLength(
          compileMinimalWithSevenConstantImports(
            eightFirst,
            eightSecond,
            eightThird,
            eightFourth,
            eightFifth,
            eightSixth,
            eightSeventh,
            eightEighth,
            artifact
          )
        );
      }

      drop(eightEighth);
      drop(eightSeventh);
      drop(eightSixth);
      drop(eightFifth);
      drop(eightFourth);
      drop(eightThird);
      drop(eightSecond);
      drop(eightFirst);
    }

    assert(0 < artifactLength);
    drop(sources);
    return artifactLength;
  }
}
