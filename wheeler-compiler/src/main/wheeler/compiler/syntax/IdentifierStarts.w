//! Classifies the bounded ASCII starts accepted for source identifiers.

module wheeler.compiler.identifier_starts;

classical class IdentifierStarts {
  private const long ASCII_UPPER_START = 65;
  private const long ASCII_UPPER_END = 91;
  private const long ASCII_UNDERSCORE = 95;
  private const long ASCII_LOWER_START = 97;
  private const long ASCII_LOWER_END = 123;

  /// Checks whether one source scalar starts an identifier.
  public boolean identifierStart(long scalar) {
    if (scalar < ASCII_UPPER_START) {
      return false;
    }

    if (scalar < ASCII_UPPER_END) {
      return true;
    }

    if (scalar < ASCII_UNDERSCORE) {
      return false;
    }

    if (scalar == ASCII_UNDERSCORE) {
      return true;
    }

    if (scalar < ASCII_LOWER_START) {
      return false;
    }

    return scalar < ASCII_LOWER_END;
  }
}
