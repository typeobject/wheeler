//! Checks canonical package-manifest outer bounds and completion.

module wheeler.compiler.packages.canonical_profile;

classical class PackageCanonicalProfile {
  private const long PACKAGE_MANIFEST_EXCLUSIVE_LIMIT = 262145;

  private long priorCoordinate(long value) {
    long one = 1;
    long prior = value - one;
    return prior;
  }

  /// Checks nonempty bounded source with one terminal newline.
  public boolean canonicalManifestBounds(borrow utf8 source) {
    long sourceLength = bufferLength(source);
    if (sourceLength < 1) {
      return false;
    }

    long exclusiveLimit = PACKAGE_MANIFEST_EXCLUSIVE_LIMIT;
    boolean bounded = sourceLength < exclusiveLimit;
    if (bounded == false) {
      return false;
    }

    long last = priorCoordinate(sourceLength);
    long finalScalar = utf8Scalar(source, last);
    if (finalScalar == 10) {
      return true;
    }

    return false;
  }

  /// Checks complete token consumption in the terminal section.
  public boolean canonicalManifestComplete(long token, long count, long section) {
    boolean consumed = token == count;
    if (consumed == false) {
      return false;
    }

    if (section == 3) {
      return true;
    }

    return false;
  }
}
