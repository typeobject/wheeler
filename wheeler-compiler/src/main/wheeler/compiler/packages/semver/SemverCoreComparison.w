//! Compares bounded semantic-version core triplets.

module wheeler.compiler.packages.semver_core_comparison;

import wheeler.compiler.packages.semver_coordinates;

classical class SemverCoreComparison {
  private long scalarComparison(long left, long right) {
    if (left < right) {
      return -1;
    }

    if (right < left) {
      return 1;
    }

    return 0;
  }

  private long firstComparison(long first, long second) {
    if (first < 0) {
      return first;
    }

    if (first == 1) {
      return first;
    }

    return second;
  }

  /// Compares major, minor, then patch values from two valid releases.
  public long semverCompareCore(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long patchComponent = 2;
    long minorComponent = 1;
    long majorComponent = 0;
    long leftPatch = semverCoreComponent(source, leftStart, leftLength, patchComponent);
    long rightPatch = semverCoreComponent(source, rightStart, rightLength, patchComponent);
    long patch = scalarComparison(leftPatch, rightPatch);
    long leftMinor = semverCoreComponent(source, leftStart, leftLength, minorComponent);
    long rightMinor = semverCoreComponent(source, rightStart, rightLength, minorComponent);
    long minor = scalarComparison(leftMinor, rightMinor);
    long minorOrPatch = firstComparison(minor, patch);
    long leftMajor = semverCoreComponent(source, leftStart, leftLength, majorComponent);
    long rightMajor = semverCoreComponent(source, rightStart, rightLength, majorComponent);
    long major = scalarComparison(leftMajor, rightMajor);
    return firstComparison(major, minorOrPatch);
  }
}
