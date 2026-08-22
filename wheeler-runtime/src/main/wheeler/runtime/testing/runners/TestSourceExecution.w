//! Compiles one bounded test source into caller-owned artifact storage.

module wheeler.runtime.testing.runners.test_source_execution;

import wheeler.compiler.driver;

classical class TestSourceExecution {
  private const long MAX_TEST_SOURCE_BYTES = 4096;
  private const long TEST_ARTIFACT_BYTES = 32768;

  /// Compiles one canonical test source through the native compiler authority.
  public long compileTestSource(borrow utf8 source, borrow mut bytes artifact) {
    assert(0 < bufferLength(source));
    assert(bufferLength(source) < MAX_TEST_SOURCE_BYTES + 1);
    assert(bufferLength(artifact) == TEST_ARTIFACT_BYTES);
    Compilation compiled = compileMinimal(source, artifact);
    assert(0 < compiled.length);
    assert(compiled.length < TEST_ARTIFACT_BYTES + 1);
    return compiled.length;
  }
}
