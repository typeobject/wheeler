//! Composes one package-manifest capability row verdict.

module wheeler.compiler.packages.manifest_capability;

import wheeler.compiler.packages.manifest_capability_coordinates;
import wheeler.compiler.packages.manifest_capability_path;
import wheeler.compiler.packages.manifest_capability_prefix;

classical class PackageManifestCapability {
  /// Checks one complete capability row at a validated token coordinate.
  public boolean manifestCapabilityRowValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
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
      return false;
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
      return false;
    }

    return true;
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
