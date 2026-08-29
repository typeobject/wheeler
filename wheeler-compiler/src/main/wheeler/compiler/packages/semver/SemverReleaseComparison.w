//! Compares bounded canonical semantic-version releases.

module wheeler.compiler.packages.semver_release_comparison;

import wheeler.compiler.packages.semver_core_comparison;
import wheeler.compiler.packages.semver_prerelease_comparison;

classical class SemverReleaseComparison {
  private long firstComparison(long first, long second) {
    if (first < 0) {
      return first;
    }

    if (first == 1) {
      return first;
    }

    return second;
  }

  /// Compares two valid canonical releases under semantic-version precedence.
  public long semverCompareReleases(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long core = semverCompareCore(source, leftStart, leftLength, rightStart, rightLength);
    long prerelease = semverComparePrerelease(
      source,
      leftStart,
      leftLength,
      rightStart,
      rightLength
    );
    return firstComparison(core, prerelease);
  }
}
