//! Classifies bytes admitted by canonical bootstrap profile names.

module wheeler.compiler.closure.manifest_profile;

classical class BootstrapManifestProfile {
  /// Checks one canonical bootstrap profile byte.
  public boolean profileByte(long scalar, boolean allowPunctuation, boolean valid) {
    if (scalar == 45) {
      return allowPunctuation;
    }

    if (scalar == 46) {
      return allowPunctuation;
    }

    if (scalar == 95) {
      return allowPunctuation;
    }

    if (scalar < 48) {
      return false;
    }

    if (scalar < 58) {
      return true;
    }

    if (scalar < 65) {
      return false;
    }

    if (scalar < 91) {
      return true;
    }

    if (scalar < 97) {
      return false;
    }

    if (scalar < 123) {
      return true;
    }

    return valid;
  }
}
