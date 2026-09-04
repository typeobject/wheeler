//! Composes the required head fields of one package-manifest target row.

module wheeler.compiler.packages.manifest_target_head;

import wheeler.compiler.packages.manifest_target_coordinates;
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

  /// Publishes the required target head and returns its row index.
  public long manifestTargetHeadRowProduct(
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words rows,
    long row,
    long kind,
    long nameToken,
    long rootToken
  ) {
    long base = row * 10;
    long nameStartColumn = base + 1;
    long nameLengthColumn = base + 2;
    long rootStartColumn = base + 3;
    long rootLengthColumn = base + 4;
    long nameStart = manifestTargetValueStart(starts, nameToken);
    long nameLength = manifestTargetValueLength(lengths, nameToken);
    long rootStart = manifestTargetValueStart(starts, rootToken);
    long rootLength = manifestTargetValueLength(lengths, rootToken);
    set(rows, base, kind);
    set(rows, nameStartColumn, nameStart);
    set(rows, nameLengthColumn, nameLength);
    set(rows, rootStartColumn, rootStart);
    set(rows, rootLengthColumn, rootLength);
    return row;
  }
}
