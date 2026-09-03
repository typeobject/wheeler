//! Composes package-manifest target source-collection policy.

module wheeler.compiler.packages.manifest_target_source_collection;

import wheeler.compiler.packages.manifest_target_source;

classical class PackageManifestTargetSourceCollection {
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

  /// Preserves earlier root coverage or admits current coverage.
  public boolean manifestTargetSourceRootCovered(boolean covered, boolean current) {
    if (covered == true) {
      return true;
    }
    return current;
  }

  /// Checks that a present source list is nonempty and covers the root.
  public boolean manifestTargetSourceCollectionComplete(
    boolean present,
    long count,
    boolean rootCovered
  ) {
    if (present == false) {
      return true;
    }
    if (count == 0) {
      return false;
    }
    return rootCovered;
  }
}
