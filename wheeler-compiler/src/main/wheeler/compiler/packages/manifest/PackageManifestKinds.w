//! Classifies canonical package-manifest scalar token values.

module wheeler.compiler.packages.manifest_kinds;

import wheeler.compiler.packages.manifest_tokens;

classical class PackageManifestKinds {
  private const long TRUE_HASH = 3569038;
  private const long FALSE_HASH = 97196323;
  private const long DEPLOYABLE_HASH = 2733284766595777;
  private const long LIBRARY_HASH = 98950456507;
  private const long TOOL_HASH = 3565976;
  private const long NORMAL_HASH = 3255221479;
  private const long DEVELOPMENT_HASH = 84736749587766587;
  private const long BUILD_HASH = 94094958;

  /// Decodes one canonical Boolean token or returns minus one.
  public long manifestBooleanToken(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token
  ) {
    long hash = tokenHash(source, starts, lengths, token);
    if (hash == TRUE_HASH) {
      return 1;
    }

    if (hash == FALSE_HASH) {
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

    long hash = quotedHash(source, starts, lengths, token);
    if (hash == DEPLOYABLE_HASH) {
      return 1;
    }

    if (hash == LIBRARY_HASH) {
      return 2;
    }

    if (hash == TOOL_HASH) {
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

    long hash = quotedHash(source, starts, lengths, token);
    if (hash == NORMAL_HASH) {
      return 1;
    }

    if (hash == DEVELOPMENT_HASH) {
      return 2;
    }

    if (hash == BUILD_HASH) {
      return 3;
    }

    return 0;
  }
}
