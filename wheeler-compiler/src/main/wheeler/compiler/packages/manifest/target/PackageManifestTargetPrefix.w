//! Validates the prefix of one package-manifest target row.

module wheeler.compiler.packages.manifest_target_prefix;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_tokens;

classical class PackageManifestTargetPrefix {
  /// Returns the target kind, or zero when the bounded row prefix is malformed.
  public long manifestTargetPrefixKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long finalRequiredToken = cursor + 12;
    boolean bounded = finalRequiredToken < count;
    if (bounded == false) {
      return 0;
    }

    boolean sequenceRow = dashAt(source, kinds, starts, cursor);
    if (sequenceRow == false) {
      return 0;
    }

    long typeKeyToken = cursor + 1;
    long typeKeyHash = 3292052;
    boolean typeKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      typeKeyToken,
      typeKeyHash
    );
    if (typeKey == false) {
      return 0;
    }

    long typeToken = cursor + 3;
    long kind = manifestTargetKind(source, kinds, starts, lengths, typeToken);
    return kind;
  }
}
