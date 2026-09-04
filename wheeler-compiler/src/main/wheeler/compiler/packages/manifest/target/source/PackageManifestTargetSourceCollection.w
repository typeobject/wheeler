//! Composes package-manifest target source-collection policy.

module wheeler.compiler.packages.manifest_target_source_collection;

import wheeler.compiler.packages.manifest_rows;
import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_source;
import wheeler.compiler.packages.manifest_target_source_coordinates;

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

  /// Updates root coverage from one admitted selector.
  public boolean manifestTargetSourceCoverage(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long selectorToken,
    long rootToken,
    boolean covered
  ) {
    boolean current = manifestTargetSourceCoversRoot(
      source,
      starts,
      lengths,
      selectorToken,
      rootToken
    );
    boolean result = manifestTargetSourceRootCovered(covered, current);
    return result;
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

  /// Admits and publishes one source entry, then returns its selector token.
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

    long sourceBase = sourceIndex * 2;
    long nextSource = sourceBase + 1;
    long selectorStart = manifestTargetSourceStart(starts, selectorToken);
    long selectorLength = manifestTargetSourceLength(lengths, selectorToken);
    set(sourceRows, sourceBase, selectorStart);
    set(sourceRows, nextSource, selectorLength);
    return selectorToken;
  }
}
