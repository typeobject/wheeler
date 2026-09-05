//! Admits and publishes package-manifest capability rows.

module wheeler.compiler.packages.manifest_capability;

import wheeler.compiler.packages.manifest_capability_coordinates;
import wheeler.compiler.packages.manifest_capability_path;
import wheeler.compiler.packages.manifest_capability_prefix;

classical class PackageManifestCapability {
  /// Returns one for admission, zero for disorder, or minus one for a malformed row.
  public long manifestCapabilityRowAdmission(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor,
    long previousNameToken,
    long previousPathToken
  ) {
    boolean validPrefix = manifestCapabilityPrefixValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validPrefix == false) {
      return -1;
    }

    boolean validPath = manifestCapabilityPathValid(
      source,
      kinds,
      starts,
      lengths,
      count,
      cursor
    );
    if (validPath == false) {
      return -1;
    }

    if (previousNameToken < 0) {
      return 1;
    }

    long nameToken = manifestCapabilityNameToken(cursor);
    long nameOrder = manifestCapabilityNameOrder(
      source,
      starts,
      lengths,
      previousNameToken,
      nameToken
    );
    if (nameOrder < 0) {
      return 1;
    }

    boolean sameName = nameOrder == 0;
    if (sameName == false) {
      return 0;
    }

    long pathToken = manifestCapabilityPathToken(cursor);
    boolean pathsOrdered = manifestCapabilityPathsOrdered(
      source,
      starts,
      lengths,
      previousPathToken,
      pathToken
    );
    if (pathsOrdered == false) {
      return 0;
    }

    return 1;
  }

  /// Publishes one validated capability row and returns the next row index.
  public long manifestCapabilityRowProduct(
    borrow mut words starts,
    borrow mut words lengths,
    long nameToken,
    long pathToken,
    borrow mut words rows,
    long row
  ) {
    long base = row * 4;
    long nameLengthColumn = base + 1;
    long pathStartColumn = base + 2;
    long pathLengthColumn = base + 3;
    long nameStart = manifestCapabilityValueStart(starts, nameToken);
    long nameLength = manifestCapabilityValueLength(lengths, nameToken);
    long pathStart = manifestCapabilityValueStart(starts, pathToken);
    long pathLength = manifestCapabilityValueLength(lengths, pathToken);
    set(rows, base, nameStart);
    set(rows, nameLengthColumn, nameLength);
    set(rows, pathStartColumn, pathStart);
    set(rows, pathLengthColumn, pathLength);
    long next = row + 1;
    return next;
  }
}
