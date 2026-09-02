//! Validates package-manifest target source selectors.

module wheeler.compiler.packages.manifest_target_source;

import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.paths;

classical class PackageManifestTargetSource {
  /// Checks one quoted logical-path selector token.
  public boolean manifestTargetSourceValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long selectorToken
  ) {
    boolean sourceQuoted = quoted(kinds, lengths, selectorToken);
    if (sourceQuoted == false) {
      return false;
    }

    long tokenStart = starts[selectorToken];
    long tokenLength = lengths[selectorToken];
    long sourceStart = tokenStart + 1;
    long sourceLength = tokenLength - 2;
    boolean sourceValid = validLogicalPath(source, sourceStart, sourceLength);
    return sourceValid;
  }
}
