//! Composes package-manifest target source-collection policy.

module wheeler.compiler.packages.manifest_target_source_collection;

import wheeler.compiler.packages.manifest_rows;
import wheeler.compiler.packages.manifest_target_coordinates;
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

  /// Admits one source entry and returns its selector token.
  public long manifestTargetSourceEntryProduct(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long rowToken,
    borrow mut words sourceRows,
    long sourceIndex,
    long previousToken
  ) {
    long selectorToken = manifestTargetSelectorToken(rowToken);
    boolean capacity = manifestSourceRowCapacity(sourceRows, sourceIndex);
    if (capacity == false) {
      return -1;
    }

    boolean ordered = manifestTargetSourceFollows(
      source,
      starts,
      lengths,
      previousToken,
      selectorToken
    );
    if (ordered == false) {
      return -1;
    }

    return selectorToken;
  }
}
