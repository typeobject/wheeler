//! Validates the token shape and selector policy of one target source row.

module wheeler.compiler.packages.manifest_target_source_row;

import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_source;
import wheeler.compiler.packages.manifest_tokens;

classical class PackageManifestTargetSourceRow {
  /// Checks one bounded dash-prefixed source-selector row.
  public boolean manifestTargetSourceRowValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long rowToken
  ) {
    long selectorToken = manifestTargetSelectorToken(rowToken);
    boolean bounded = selectorToken < count;
    if (bounded == false) {
      return false;
    }

    boolean sequenceRow = dashAt(source, kinds, starts, rowToken);
    if (sequenceRow == false) {
      return false;
    }

    boolean validSelector = manifestTargetSourceValid(
      source,
      kinds,
      starts,
      lengths,
      selectorToken
    );
    return validSelector;
  }
}
