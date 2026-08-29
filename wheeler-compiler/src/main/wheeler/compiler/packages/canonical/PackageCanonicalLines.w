//! Checks canonical package-manifest token layout inside one line.

module wheeler.compiler.packages.canonical_lines;

import wheeler.compiler.packages.canonical_line_kinds;

classical class PackageCanonicalLines {
  private boolean plainBaseShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    long keyEnd = starts[first] + lengths[first];
    boolean adjacentColon = starts[first + 1] == keyEnd;
    if (adjacentColon == false) {
      return false;
    }

    boolean punctuationKind = kinds[first + 1] == 3;
    if (punctuationKind == false) {
      return false;
    }

    if (utf8Scalar(source, starts[first + 1]) == 58) {
      return true;
    }

    return false;
  }

  private boolean plainValueSpacing(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    long colonEnd = starts[first + 1] + lengths[first + 1];
    long valueStart = colonEnd + 1;
    boolean adjacentValue = starts[first + 2] == valueStart;
    if (adjacentValue == false) {
      return false;
    }

    if (utf8Scalar(source, colonEnd) == 32) {
      return true;
    }

    return false;
  }

  private boolean plainFinalSpacing(
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    long finalStart = starts[first + 2] + lengths[first + 2];
    if (starts[first + 3] == finalStart) {
      return true;
    }

    return false;
  }

  private boolean plainTwoTokenShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    return plainBaseShape(source, kinds, starts, lengths, first);
  }

  private boolean plainThreeTokenShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    boolean base = plainBaseShape(source, kinds, starts, lengths, first);
    if (base == false) {
      return false;
    }

    return plainValueSpacing(source, starts, lengths, first);
  }

  private boolean plainFourTokenShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    boolean firstThree = plainThreeTokenShape(source, kinds, starts, lengths, first);
    if (firstThree == false) {
      return false;
    }

    return plainFinalSpacing(starts, lengths, first);
  }

  private boolean plainLineShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first,
    long lineTokens
  ) {
    boolean validCount = canonicalPlainLineTokenCount(lineTokens);
    if (validCount == false) {
      return false;
    }

    if (lineTokens == 2) {
      return plainTwoTokenShape(source, kinds, starts, lengths, first);
    }

    if (lineTokens == 3) {
      return plainThreeTokenShape(source, kinds, starts, lengths, first);
    }

    if (lineTokens == 4) {
      return plainFourTokenShape(source, kinds, starts, lengths, first);
    }

    return false;
  }

  private boolean dashedBaseShape(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    long dashEnd = starts[first] + lengths[first];
    long valueStart = dashEnd + 1;
    boolean adjacentValue = starts[first + 1] == valueStart;
    if (adjacentValue == false) {
      return false;
    }

    if (utf8Scalar(source, dashEnd) == 32) {
      return true;
    }

    return false;
  }

  private boolean dashedFieldSpacing(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    long keyEnd = starts[first + 1] + lengths[first + 1];
    boolean adjacentColon = starts[first + 2] == keyEnd;
    if (adjacentColon == false) {
      return false;
    }

    boolean colon = utf8Scalar(source, starts[first + 2]) == 58;
    if (colon == false) {
      return false;
    }

    long colonEnd = starts[first + 2] + lengths[first + 2];
    long fieldStart = colonEnd + 1;
    boolean adjacentField = starts[first + 3] == fieldStart;
    if (adjacentField == false) {
      return false;
    }

    if (utf8Scalar(source, colonEnd) == 32) {
      return true;
    }

    return false;
  }

  private boolean dashedTwoTokenShape(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    return dashedBaseShape(source, starts, lengths, first);
  }

  private boolean dashedFourTokenShape(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    boolean base = dashedBaseShape(source, starts, lengths, first);
    if (base == false) {
      return false;
    }

    return dashedFieldSpacing(source, starts, lengths, first);
  }

  private boolean dashedLineShape(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long first,
    long lineTokens
  ) {
    boolean validCount = canonicalDashedLineTokenCount(lineTokens);
    if (validCount == false) {
      return false;
    }

    if (lineTokens == 2) {
      return dashedTwoTokenShape(source, starts, lengths, first);
    }

    if (lineTokens == 4) {
      return dashedFourTokenShape(source, starts, lengths, first);
    }

    return false;
  }

  private boolean dashedLineStart(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long first
  ) {
    boolean punctuationKind = kinds[first] == 3;
    if (punctuationKind == false) {
      return false;
    }

    if (utf8Scalar(source, starts[first]) == 45) {
      return true;
    }

    return false;
  }

  /// Checks punctuation and spacing for one plain or dashed line.
  public boolean canonicalLineShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first,
    long lineTokens
  ) {
    boolean dashed = dashedLineStart(source, kinds, starts, first);
    if (dashed == true) {
      return dashedLineShape(source, starts, lengths, first, lineTokens);
    }

    return plainLineShape(source, kinds, starts, lengths, first, lineTokens);
  }

  /// Checks that the final token ends exactly at the line delimiter.
  public boolean canonicalLineEndMatches(
    borrow mut words starts,
    borrow mut words lengths,
    long first,
    long lineTokens,
    long lineEnd
  ) {
    if (lineTokens < 1) {
      return false;
    }

    long finalToken = canonicalFinalLineToken(first, lineTokens);
    long finalEnd = starts[finalToken] + lengths[finalToken];
    if (finalEnd == lineEnd) {
      return true;
    }

    return false;
  }
}
