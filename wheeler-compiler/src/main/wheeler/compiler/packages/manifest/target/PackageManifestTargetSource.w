//! Validates package-manifest target source selectors.

module wheeler.compiler.packages.manifest_target_source;

import wheeler.compiler.packages.manifest_selectors;
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

  /// Checks strict lexical order between adjacent source selectors.
  public boolean manifestTargetSourcesOrdered(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long previousToken,
    long currentToken
  ) {
    long order = compareTokenText(source, starts, lengths, previousToken, currentToken);
    return order < 0;
  }

  /// Checks whether one selector covers the target root.
  public boolean manifestTargetSourceCoversRoot(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long selectorToken,
    long rootToken
  ) {
    long selectorTokenStart = starts[selectorToken];
    long selectorTokenLength = lengths[selectorToken];
    long rootTokenStart = starts[rootToken];
    long rootTokenLength = lengths[rootToken];
    long selectorStart = selectorTokenStart + 1;
    long selectorLength = selectorTokenLength - 2;
    long rootStart = rootTokenStart + 1;
    long rootLength = rootTokenLength - 2;
    boolean covers = manifestSelectorRangeCoversRoot(
      source,
      selectorStart,
      selectorLength,
      rootStart,
      rootLength
    );
    return covers;
  }
}
