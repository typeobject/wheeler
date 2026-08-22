//! Compiles a previously validated bounded target-source plan.

module wheeler.runtime.testing.runners.test_source_compilation;

import wheeler.compiler.driver;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourceCompilation {
  private const long MAX_COMPILED_SOURCES = 7;
  private const long MAX_TEST_SOURCE_BYTES = 4096;
  private const long TEST_ARTIFACT_BYTES = 32768;

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

  /// Compiles one validated one-to-three-source plan into recovery storage.
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
    region sources = new region(/* bytes= */ 28672, /* allocations= */ 7);
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

    assert(0 < artifactLength);
    drop(sources);
    return artifactLength;
  }
}
