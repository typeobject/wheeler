//! Checks one bounded package-output provenance witness before acceptance.

module examples.package.provenance;

classical class PackageProvenance {
  state long accepted = 0;
  state long outputLength = 0;
  state long dependencyCount = 0;
  state long changedFields = 0;

  private long verify(
    long archiveIdentity,
    long manifestIdentity,
    long lockRootManifestIdentity,
    long sourceIdentity,
    long planSourceIdentity,
    long toolchainIdentity,
    long lockedDependencyIdentity,
    long plannedDependencyIdentity,
    long expectedOutputIdentity,
    long actualOutputIdentity,
    long actualOutputLength
  ) {
    assert(0 < archiveIdentity);
    assert(0 < manifestIdentity);
    assert(manifestIdentity == lockRootManifestIdentity);
    assert(sourceIdentity == planSourceIdentity);
    assert(0 < toolchainIdentity);
    assert(lockedDependencyIdentity == plannedDependencyIdentity);
    assert(expectedOutputIdentity == actualOutputIdentity);
    assert(0 < actualOutputLength);
    return actualOutputLength;
  }

  /// Accepts one exact provenance witness with no ambient resolution or target work.
  ///
  /// - Effects: Mutates declared result state after every witness edge matches.
  entry void main() {
    outputLength = verify(11, 13, 13, 17, 17, 19, 23, 23, 29, 29, 31);
    dependencyCount = 1;
    accepted = 1;
  }
}
