//! Composes the required test tail of one package-manifest target row.

module wheeler.compiler.packages.manifest_target_tail;

import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_test;

classical class PackageManifestTargetTail {
  /// Returns the test Boolean when the source collection and required tail are valid.
  public long manifestTargetTestValue(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long kind,
    long keyToken,
    boolean sourceCollectionComplete
  ) {
    if (sourceCollectionComplete == false) {
      return -1;
    }

    boolean present = manifestTargetTestPresent(
      source,
      kinds,
      starts,
      lengths,
      count,
      keyToken
    );
    if (present == false) {
      return -1;
    }

    long testToken = manifestTargetTestToken(keyToken);
    long test = manifestBooleanToken(source, starts, lengths, testToken);
    if (test < 0) {
      return -1;
    }

    boolean allowed = manifestTargetTestAllowed(kind, test);
    if (allowed == false) {
      return -1;
    }

    return test;
  }

  /// Publishes a modular target tail and advances the row.
  public long manifestModularTargetTailRowProduct(
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words rows,
    long row,
    long moduleToken,
    long sourceOffset,
    long sourceCount,
    long test
  ) {
    long moduleStart = manifestTargetValueStart(starts, moduleToken);
    long moduleLength = manifestTargetValueLength(lengths, moduleToken);
    long base = row * 10;
    long moduleStartColumn = base + 5;
    long moduleLengthColumn = base + 6;
    long sourceOffsetColumn = base + 7;
    long sourceCountColumn = base + 8;
    long testColumn = base + 9;
    set(rows, moduleStartColumn, moduleStart);
    set(rows, moduleLengthColumn, moduleLength);
    set(rows, sourceOffsetColumn, sourceOffset);
    set(rows, sourceCountColumn, sourceCount);
    set(rows, testColumn, test);
    long next = row + 1;
    return next;
  }

  /// Publishes a nonmodular target tail and advances the row.
  public long manifestNonmodularTargetTailRowProduct(
    borrow mut words rows,
    long row,
    long sourceOffset,
    long sourceCount,
    long test
  ) {
    long base = row * 10;
    long moduleStartColumn = base + 5;
    long moduleLengthColumn = base + 6;
    long sourceOffsetColumn = base + 7;
    long sourceCountColumn = base + 8;
    long testColumn = base + 9;
    long absentModule = 0;
    set(rows, moduleStartColumn, absentModule);
    set(rows, moduleLengthColumn, absentModule);
    set(rows, sourceOffsetColumn, sourceOffset);
    set(rows, sourceCountColumn, sourceCount);
    set(rows, testColumn, test);
    long next = row + 1;
    return next;
  }
}
