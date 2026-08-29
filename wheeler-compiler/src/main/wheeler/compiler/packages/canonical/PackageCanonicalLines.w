//! Checks canonical package-manifest token layout inside one line.

module wheeler.compiler.packages.canonical_lines;

import wheeler.compiler.packages.canonical_line_kinds;

classical class PackageCanonicalLines {
  private long rowValue(borrow mut words rows, long index) {
    long value = rows[index];
    return value;
  }

  private boolean plainBaseShape(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    long one = 1;
    long colonIndex = first + one;
    long keyStart = rowValue(starts, first);
    long keyLength = rowValue(lengths, first);
    long keyEnd = keyStart + keyLength;
    long colonStart = rowValue(starts, colonIndex);
    boolean adjacentColon = colonStart == keyEnd;
    if (adjacentColon == false) {
      return false;
    }

    long colonKind = rowValue(kinds, colonIndex);
    boolean punctuationKind = colonKind == 3;
    if (punctuationKind == false) {
      return false;
    }

    if (utf8Scalar(source, colonStart) == 58) {
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
    long one = 1;
    long colonIndex = first + one;
    long valueIndex = colonIndex + one;
    long colonStart = rowValue(starts, colonIndex);
    long colonLength = rowValue(lengths, colonIndex);
    long colonEnd = colonStart + colonLength;
    long valueStart = colonEnd + one;
    long actualValueStart = rowValue(starts, valueIndex);
    boolean adjacentValue = actualValueStart == valueStart;
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
    long one = 1;
    long colonIndex = first + one;
    long valueIndex = colonIndex + one;
    long finalIndex = valueIndex + one;
    long valueStart = rowValue(starts, valueIndex);
    long valueLength = rowValue(lengths, valueIndex);
    long finalStart = valueStart + valueLength;
    long actualFinalStart = rowValue(starts, finalIndex);
    if (actualFinalStart == finalStart) {
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
    long one = 1;
    long valueIndex = first + one;
    long dashStart = rowValue(starts, first);
    long dashLength = rowValue(lengths, first);
    long dashEnd = dashStart + dashLength;
    long valueStart = dashEnd + one;
    long actualValueStart = rowValue(starts, valueIndex);
    boolean adjacentValue = actualValueStart == valueStart;
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
    long one = 1;
    long keyIndex = first + one;
    long colonIndex = keyIndex + one;
    long fieldIndex = colonIndex + one;
    long keyStart = rowValue(starts, keyIndex);
    long keyLength = rowValue(lengths, keyIndex);
    long keyEnd = keyStart + keyLength;
    long colonStart = rowValue(starts, colonIndex);
    boolean adjacentColon = colonStart == keyEnd;
    if (adjacentColon == false) {
      return false;
    }

    boolean colon = utf8Scalar(source, colonStart) == 58;
    if (colon == false) {
      return false;
    }

    long colonLength = rowValue(lengths, colonIndex);
    long colonEnd = colonStart + colonLength;
    long fieldStart = colonEnd + one;
    long actualFieldStart = rowValue(starts, fieldIndex);
    boolean adjacentField = actualFieldStart == fieldStart;
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
    long firstKind = rowValue(kinds, first);
    boolean punctuationKind = firstKind == 3;
    if (punctuationKind == false) {
      return false;
    }

    long firstStart = rowValue(starts, first);
    if (utf8Scalar(source, firstStart) == 45) {
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
    long finalStart = rowValue(starts, finalToken);
    long finalLength = rowValue(lengths, finalToken);
    long finalEnd = finalStart + finalLength;
    if (finalEnd == lineEnd) {
      return true;
    }

    return false;
  }
}
