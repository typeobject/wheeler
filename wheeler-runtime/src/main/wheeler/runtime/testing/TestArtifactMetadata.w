//! Projects test-report metadata from one verified artifact.

module wheeler.runtime.testing.test_artifact_metadata;

import wheeler.core.encoding.binary;

classical class TestArtifactMetadata {
  public record ArtifactText(long start, long length) {}

  private long sectionOffset(borrow byteview artifact, long section) {
    return readUnsigned(artifact, 40 + section * 32 + 8, /* width= */ 8);
  }

  private ArtifactText stringText(borrow byteview artifact, long selected) {
    long strings = sectionOffset(artifact, /* section= */ 1);
    long count = readUnsigned(artifact, strings, /* width= */ 4);
    assert(selected < count);
    long cursor = strings + 4;
    long index = 0;
    while (index < count) limit 65535 {
      long length = readUnsigned(artifact, cursor, /* width= */ 4);
      cursor += 4;
      if (index == selected) {
        return new ArtifactText(cursor, length);
      }

      cursor += length;
      index += 1;
    }

    assert(false);
    return new ArtifactText(/* start= */ 0, /* length= */ 0);
  }

  /// Returns the verified manifest program name range.
  public ArtifactText artifactProgramText(borrow byteview artifact) {
    long manifest = sectionOffset(artifact, /* section= */ 0);
    long name = readUnsigned(artifact, manifest, /* width= */ 4);
    return stringText(artifact, name);
  }

  /// Returns the verified manifest program kind code.
  public long artifactProgramKind(borrow byteview artifact) {
    long manifest = sectionOffset(artifact, /* section= */ 0);
    return readUnsigned(artifact, manifest + 12, /* width= */ 4);
  }

  /// Returns the active verified global count.
  public long artifactGlobalCount(borrow byteview artifact) {
    long types = sectionOffset(artifact, /* section= */ 2);
    return readUnsigned(artifact, types, /* width= */ 4);
  }

  /// Returns one verified global name range in descriptor order.
  public ArtifactText artifactGlobalText(borrow byteview artifact, long global) {
    long types = sectionOffset(artifact, /* section= */ 2);
    long count = readUnsigned(artifact, types, /* width= */ 4);
    assert(global < count);
    long name = readUnsigned(artifact, types + 4 + global * 16, /* width= */ 4);
    return stringText(artifact, name);
  }
}
