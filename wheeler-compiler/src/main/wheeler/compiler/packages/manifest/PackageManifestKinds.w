//! Classifies canonical package-manifest scalar token values.

module wheeler.compiler.packages.manifest_kinds;

import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;

classical class PackageManifestKinds {
  /// Decodes one canonical Boolean token or returns minus one.
  public long manifestBooleanToken(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long word = manifestTokenWord(source, starts, lengths, token);
    if (word == WORD_TRUE) {
      return 1;
    }

    if (word == WORD_FALSE) {
      return 0;
    }

    return -1;
  }

  /// Decodes deployable, library, or tool target kind.
  public long manifestTargetKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    boolean quotedToken = quoted(kinds, lengths, token);
    if (quotedToken == false) {
      return 0;
    }

    long word = manifestQuotedWord(source, starts, lengths, token);
    if (word == WORD_DEPLOYABLE) {
      return 1;
    }

    if (word == WORD_LIBRARY) {
      return 2;
    }

    if (word == WORD_TOOL) {
      return 3;
    }

    return 0;
  }

  /// Decodes normal, development, or build dependency kind.
  public long manifestDependencyKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    boolean quotedToken = quoted(kinds, lengths, token);
    if (quotedToken == false) {
      return 0;
    }

    long word = manifestQuotedWord(source, starts, lengths, token);
    if (word == WORD_NORMAL) {
      return 1;
    }

    if (word == WORD_DEVELOPMENT) {
      return 2;
    }

    if (word == WORD_BUILD) {
      return 3;
    }

    return 0;
  }
}
