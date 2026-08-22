//! Compiles one bounded test source into caller-owned artifact storage.

module wheeler.runtime.testing.runners.test_source_execution;

import wheeler.compiler.driver;

classical class TestSourceExecution {
  private const long MAX_TEST_SOURCE_BYTES = 4096;
  private const long TEST_ARTIFACT_BYTES = 32768;

  private void validateSource(borrow utf8 source) {
    assert(0 < bufferLength(source));
    assert(bufferLength(source) < MAX_TEST_SOURCE_BYTES + 1);
  }

  private long checkedLength(Compilation compiled) {
    assert(0 < compiled.length);
    assert(compiled.length < TEST_ARTIFACT_BYTES + 1);
    return compiled.length;
  }

  /// Compiles one canonical test source through the native compiler authority.
  public long compileTestSource(borrow utf8 source, borrow mut bytes artifact) {
    validateSource(source);
    assert(bufferLength(artifact) == TEST_ARTIFACT_BYTES);
    return checkedLength(compileMinimal(source, artifact));
  }

  /// Compiles one imported source and its canonical root.
  public long compileImportedTestSource(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut bytes artifact
  ) {
    validateSource(importedSource);
    validateSource(rootSource);
    assert(bufferLength(artifact) == TEST_ARTIFACT_BYTES);
    return checkedLength(compileMinimalWithConstantImport(importedSource, rootSource, artifact));
  }

  /// Compiles two imported sources and their canonical root.
  public long compileTwoImportedTestSources(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes artifact
  ) {
    validateSource(firstImportedSource);
    validateSource(secondImportedSource);
    validateSource(rootSource);
    assert(bufferLength(artifact) == TEST_ARTIFACT_BYTES);
    return checkedLength(
      compileMinimalWithConstantImports(
        firstImportedSource,
        secondImportedSource,
        rootSource,
        artifact
      )
    );
  }
}
