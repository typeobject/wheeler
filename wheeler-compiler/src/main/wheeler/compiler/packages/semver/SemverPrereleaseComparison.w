//! Compares bounded semantic-version prerelease sequences.

module wheeler.compiler.packages.semver_prerelease_comparison;

import wheeler.compiler.packages.semver_coordinates;
import wheeler.compiler.packages.semver_identifier_comparison;

classical class SemverPrereleaseComparison {
  private long scalarComparison(long left, long right) {
    if (left < right) {
      return -1;
    }

    if (right < left) {
      return 1;
    }

    return 0;
  }

  private long prereleaseKind(long start, long end) {
    if (start == end) {
      return 1;
    }

    return 0;
  }

  private long activeIdentifierEnd(
    long comparison,
    long left,
    long leftDocumentEnd,
    long right,
    long rightDocumentEnd
  ) {
    if (comparison < 0) {
      return left;
    }

    if (comparison == 1) {
      return left;
    }

    if (right < rightDocumentEnd) {
      return leftDocumentEnd;
    }

    return left;
  }

  private long projectedIdentifierEnd(borrow utf8 source, long start, long end) {
    return semverIdentifierEnd(source, start, end);
  }

  private long identifierComparison(
    borrow utf8 source,
    long leftStart,
    long leftEnd,
    long rightStart,
    long rightEnd
  ) {
    return semverCompareIdentifier(source, leftStart, leftEnd, rightStart, rightEnd);
  }

  private long identifierTailComparison(
    long comparison,
    long left,
    long leftDocumentEnd,
    long right,
    long rightDocumentEnd
  ) {
    if (comparison < 0) {
      return comparison;
    }

    if (comparison == 1) {
      return comparison;
    }

    if (left < leftDocumentEnd) {
      return 1;
    }

    if (right < rightDocumentEnd) {
      return -1;
    }

    return 0;
  }

  /// Compares the prerelease portions of two valid releases.
  public long semverComparePrerelease(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long leftDocumentEnd = leftStart + leftLength;
    long rightDocumentEnd = rightStart + rightLength;
    long left = semverPrereleaseStart(source, leftStart, leftLength);
    long right = semverPrereleaseStart(source, rightStart, rightLength);
    long leftKind = prereleaseKind(left, leftDocumentEnd);
    long rightKind = prereleaseKind(right, rightDocumentEnd);
    long comparison = scalarComparison(leftKind, rightKind);
    long scanEnd = activeIdentifierEnd(
      comparison,
      left,
      leftDocumentEnd,
      right,
      rightDocumentEnd
    );
    while (left < scanEnd) limit 64 {
      long leftEnd = projectedIdentifierEnd(source, left, leftDocumentEnd);
      long rightEnd = projectedIdentifierEnd(source, right, rightDocumentEnd);
      long nextComparison = identifierComparison(source, left, leftEnd, right, rightEnd);
      long nextLeft = leftEnd;
      long nextRight = rightEnd;
      nextLeft += 1;
      nextRight += 1;
      long nextScanEnd = activeIdentifierEnd(
        nextComparison,
        nextLeft,
        leftDocumentEnd,
        nextRight,
        rightDocumentEnd
      );
      comparison = nextComparison;
      left = nextLeft;
      right = nextRight;
      scanEnd = nextScanEnd;
    }

    return identifierTailComparison(comparison, left, leftDocumentEnd, right, rightDocumentEnd);
  }
}
