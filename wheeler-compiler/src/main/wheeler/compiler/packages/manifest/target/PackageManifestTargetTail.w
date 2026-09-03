//! Composes the required test tail of one package-manifest target row.

module wheeler.compiler.packages.manifest_target_tail;

import wheeler.compiler.packages.manifest_kinds;
import wheeler.compiler.packages.manifest_target_coordinates;
import wheeler.compiler.packages.manifest_target_test;

classical class PackageManifestTargetTail {
  /// Returns the test Boolean, or a negative value when the required tail is malformed.
  public long manifestTargetTestValue(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long kind,
    long keyToken
  ) {
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
}
