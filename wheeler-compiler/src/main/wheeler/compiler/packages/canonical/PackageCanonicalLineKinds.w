//! Classifies canonical package-manifest line token counts.

module wheeler.compiler.packages.canonical_line_kinds;

classical class PackageCanonicalLineKinds {
  /// Accepts key, key-value, and split-value plain lines.
  public boolean canonicalPlainLineTokenCount(long count) {
    if (count == 2) {
      return true;
    }

    if (count == 3) {
      return true;
    }

    if (count == 4) {
      return true;
    }

    return false;
  }

  /// Accepts dashed values and dashed key-value lines.
  public boolean canonicalDashedLineTokenCount(long count) {
    if (count == 2) {
      return true;
    }

    if (count == 4) {
      return true;
    }

    return false;
  }

  /// Returns the final token coordinate in one nonempty line window.
  public long canonicalFinalLineToken(long first, long count) {
    long end = first + count;
    return end - 1;
  }
}
