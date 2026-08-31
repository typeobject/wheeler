//! Validates the package-manifest format preamble.

module wheeler.compiler.packages.manifest_header_preamble;

import wheeler.compiler.packages.manifest_header_state;
import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;

classical class PackageManifestHeaderPreamble {
  /// Checks token capacity, format version, and the package mapping opener.
  public boolean manifestHeaderPreambleValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    boolean enoughTokens = manifestHeaderTokenCount(count);
    if (enoughTokens == false) {
      return false;
    }

    long formatToken = 0;
    long formatHash = 3386979745;
    boolean formatKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      formatToken,
      formatHash
    );
    if (formatKey == false) {
      return false;
    }

    long versionToken = 2;
    long versionHash = tokenHash(source, starts, lengths, versionToken);
    boolean formatVersion = manifestFormatVersion(versionHash);
    if (formatVersion == false) {
      return false;
    }

    long packageToken = 3;
    long packageHash = 102272152646;
    boolean packageKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      packageToken,
      packageHash
    );
    return packageKey;
  }
}
