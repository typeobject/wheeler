//! Composes fixed package-manifest header validation.

module wheeler.compiler.packages.manifest_header;

import wheeler.compiler.packages.manifest_header_name;
import wheeler.compiler.packages.manifest_header_preamble;
import wheeler.compiler.packages.manifest_header_release;
import wheeler.compiler.packages.manifest_header_tail;

classical class PackageManifestHeader {
  /// Checks the complete fixed header before collection parsing.
  public boolean manifestHeaderValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    boolean preambleValid = manifestHeaderPreambleValid(source, kinds, starts, lengths, count);
    if (preambleValid == false) {
      return false;
    }

    boolean nameValid = manifestHeaderNameValid(source, kinds, starts, lengths, count);
    if (nameValid == false) {
      return false;
    }

    boolean releaseValid = manifestHeaderReleaseValid(source, kinds, starts, lengths, count);
    if (releaseValid == false) {
      return false;
    }

    boolean tailValid = manifestHeaderTailValid(source, kinds, starts, lengths, count);
    return tailValid;
  }
}
