//! Composes one package-manifest capability row verdict.

module wheeler.compiler.packages.manifest_capability;

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
}
