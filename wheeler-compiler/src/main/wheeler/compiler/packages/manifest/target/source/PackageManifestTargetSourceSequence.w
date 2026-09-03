//! Composes first-row and adjacent-row source-selector ordering.

module wheeler.compiler.packages.manifest_target_source_sequence;

import wheeler.compiler.packages.manifest_target_source;

classical class PackageManifestTargetSourceSequence {
  /// Accepts a first selector or checks strict order after its predecessor.
  public boolean manifestTargetSourceFollows(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long previousToken,
    long selectorToken
  ) {
    if (previousToken < 0) {
      return true;
    }

    boolean ordered = manifestTargetSourcesOrdered(
      source,
      starts,
      lengths,
      previousToken,
      selectorToken
    );
    return ordered;
  }
}
