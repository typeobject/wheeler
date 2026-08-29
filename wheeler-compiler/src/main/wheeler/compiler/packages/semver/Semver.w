//! Compares canonical semantic versions and exposes their validation facade.

module wheeler.compiler.packages.semver;

import wheeler.compiler.packages.semver_prerelease_validation;
import wheeler.compiler.packages.semver_release_comparison;

classical class Semver {
  /// Checks whether `release` satisfies the canonical profile.
  public boolean validRelease(borrow utf8 source, long start, long length) {
    return semverValidRelease(source, start, length);
  }

  /// Checks whether `constraint` satisfies the canonical profile.
  public boolean validConstraint(borrow utf8 source, long start, long length) {
    return semverValidConstraint(source, start, length);
  }

  /// Compares two valid canonical releases under semantic-version precedence.
  public long compareReleases(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    return semverCompareReleases(source, leftStart, leftLength, rightStart, rightLength);
  }
}
