//! Compiles a previously validated bounded target-source plan.

module wheeler.runtime.testing.runners.test_source_compilation;

import wheeler.compiler.driver;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestSourceCompilation {
  private const long MAX_COMPILED_SOURCES = 3;
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
    region sources = new region(/* bytes= */ 12288, /* allocations= */ 3);
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

    assert(0 < artifactLength);
    drop(sources);
    return artifactLength;
  }
}
