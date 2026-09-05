//! Recognizes top-level package-manifest collection sections.

module wheeler.compiler.packages.manifest_sections;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_words;

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
    long dependenciesWord = WORD_DEPENDENCIES;
    boolean present = manifestKeyAt(
      source, kinds, starts, lengths, count, keyToken, dependenciesWord
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
    long capabilitiesWord = WORD_CAPABILITIES;
    boolean present = manifestKeyAt(
      source, kinds, starts, lengths, count, keyToken, capabilitiesWord
    );
    return present;
  }
}
