//! Recognizes top-level package-manifest collection sections.

module wheeler.compiler.packages.manifest_sections;

import wheeler.compiler.packages.manifest_keys;

classical class PackageManifestSections {
  /// Checks whether the dependencies section starts at one token.
  public boolean manifestDependenciesPresent(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long keyToken
  ) {
    long keyHash = 2626680644436426025;
    boolean present = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      keyToken,
      keyHash
    );
    return present;
  }

  /// Checks whether the capabilities section starts at one token.
  public boolean manifestCapabilitiesPresent(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long keyToken
  ) {
    long keyHash = 2597989917310390198;
    boolean present = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      keyToken,
      keyHash
    );
    return present;
  }
}
