//! Admits and publishes package-manifest dependency rows.

module wheeler.compiler.packages.manifest_dependency;

import wheeler.compiler.packages.manifest_dependency_coordinates;
import wheeler.compiler.packages.manifest_dependency_name;
import wheeler.compiler.packages.manifest_dependency_prefix;
import wheeler.compiler.packages.manifest_dependency_version;

classical class PackageManifestDependency {
  /// Admits one row, returning its kind, zero for disorder, or minus one when malformed.
  public long manifestDependencyRowAdmission(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor,
    long previousNameToken
  ) {
    long kind = manifestDependencyPrefix(source, kinds, starts, lengths, count, cursor);
    if (kind < 1) {
      return -1;
    }

    boolean validName = manifestDependencyNameValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validName == false) {
      return -1;
    }

    boolean validVersion = manifestDependencyVersionValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validVersion == false) {
      return -1;
    }

    if (previousNameToken < 0) {
      return kind;
    }

    long nameToken = manifestDependencyNameToken(cursor);
    boolean ordered = manifestDependencyNamesOrdered(
      source,
      starts,
      lengths,
      previousNameToken,
      nameToken
    );
    if (ordered == false) {
      return 0;
    }

    return kind;
  }

  /// Publishes one validated dependency row and returns the next row index.
  public long manifestDependencyRowProduct(
    borrow mut words starts,
    borrow mut words lengths,
    long kind,
    long nameToken,
    long versionToken,
    borrow mut words rows,
    long row
  ) {
    long base = row * 5;
    long nameStartColumn = base + 1;
    long nameLengthColumn = base + 2;
    long versionStartColumn = base + 3;
    long versionLengthColumn = base + 4;
    long nameStart = manifestDependencyValueStart(starts, nameToken);
    long nameLength = manifestDependencyValueLength(lengths, nameToken);
    long versionStart = manifestDependencyValueStart(starts, versionToken);
    long versionLength = manifestDependencyValueLength(lengths, versionToken);
    set(rows, base, kind);
    set(rows, nameStartColumn, nameStart);
    set(rows, nameLengthColumn, nameLength);
    set(rows, versionStartColumn, versionStart);
    set(rows, versionLengthColumn, versionLength);
    long next = row + 1;
    return next;
  }
}
