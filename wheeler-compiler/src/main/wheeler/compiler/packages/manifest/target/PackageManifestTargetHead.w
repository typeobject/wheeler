//! Composes the required head fields of one package-manifest target row.

module wheeler.compiler.packages.manifest_target_head;

import wheeler.compiler.packages.manifest_target_name;
import wheeler.compiler.packages.manifest_target_prefix;
import wheeler.compiler.packages.manifest_target_root;

classical class PackageManifestTargetHead {
  /// Returns the target kind, or zero when a required head field is malformed.
  public long manifestTargetHeadKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long kind = manifestTargetPrefixKind(source, kinds, starts, lengths, count, cursor);
    if (kind < 1) {
      return 0;
    }

    boolean validName = manifestTargetNameValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validName == false) {
      return 0;
    }

    boolean validRoot = manifestTargetRootValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validRoot == false) {
      return 0;
    }

    return kind;
  }
}
