//! Compares canonical semantic versions and exposes their validation facade.

module wheeler.compiler.packages.semver;

import wheeler.compiler.packages.semver_coordinates;
import wheeler.compiler.packages.semver_identifier_comparison;
import wheeler.compiler.packages.semver_prerelease_validation;

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
    long component = 0;
    while (component < 3) limit 3 {
      long leftValue = semverCoreComponent(source, leftStart, leftLength, component);
      long rightValue = semverCoreComponent(source, rightStart, rightLength, component);
      if (leftValue < rightValue) {
        return -1;
      }

      if (rightValue < leftValue) {
        return 1;
      }

      component += 1;
    }

    long leftDocumentEnd = leftStart + leftLength;
    long rightDocumentEnd = rightStart + rightLength;
    long left = semverPrereleaseStart(source, leftStart, leftLength);
    long right = semverPrereleaseStart(source, rightStart, rightLength);
    boolean leftStable = left == leftDocumentEnd;
    boolean rightStable = right == rightDocumentEnd;
    if (leftStable) {
      if (rightStable) {
        return 0;
      }

      return 1;
    }

    if (rightStable) {
      return -1;
    }

    while (left < leftDocumentEnd) limit 64 {
      if (right < rightDocumentEnd) {
        long leftEnd = semverIdentifierEnd(source, left, leftDocumentEnd);
        long rightEnd = semverIdentifierEnd(source, right, rightDocumentEnd);
        long comparison = semverCompareIdentifier(source, left, leftEnd, right, rightEnd);
        if (comparison == 0) {
          left = leftEnd + 1;
          right = rightEnd + 1;
        } else {
          return comparison;
        }
      } else {
        return 1;
      }
    }

    if (right < rightDocumentEnd) {
      return -1;
    }

    return 0;
  }
}
