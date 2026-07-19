package com.typeobject.wheeler.packageformat;

import java.util.Objects;

/** Deterministic exact, caret, or tilde requirement with fail-closed prerelease policy. */
public record VersionConstraint(Kind kind, SemanticVersion minimum) {
  public VersionConstraint {
    Objects.requireNonNull(kind, "kind");
    Objects.requireNonNull(minimum, "minimum");
  }

  public static VersionConstraint parse(String text) {
    if (text == null || text.isEmpty()) {
      throw new PackageFormatException("Empty version constraint");
    }
    Kind kind = switch (text.charAt(0)) {
      case '^' -> Kind.CARET;
      case '~' -> Kind.TILDE;
      case '=' -> Kind.EXACT;
      default -> Kind.EXACT;
    };
    String version = kind == Kind.EXACT && text.charAt(0) != '=' ? text : text.substring(1);
    return new VersionConstraint(kind, SemanticVersion.parse(version));
  }

  @Override
  public String toString() {
    return switch (kind) {
      case EXACT -> "=" + minimum;
      case CARET -> "^" + minimum;
      case TILDE -> "~" + minimum;
    };
  }

  public boolean accepts(SemanticVersion candidate) {
    // A stable requirement must not start selecting previews merely because a repository grew one.
    if (!candidate.prerelease().isEmpty() && minimum.prerelease().isEmpty()) {
      return false;
    }
    if (candidate.compareTo(minimum) < 0) {
      return false;
    }
    return switch (kind) {
      case EXACT -> candidate.equals(minimum);
      case TILDE -> candidate.major() == minimum.major()
          && candidate.minor() == minimum.minor();
      case CARET -> {
        if (minimum.major() > 0) {
          yield candidate.major() == minimum.major();
        }
        if (minimum.minor() > 0) {
          yield candidate.major() == 0 && candidate.minor() == minimum.minor();
        }
        yield candidate.major() == 0
            && candidate.minor() == 0
            && candidate.patch() == minimum.patch();
      }
    };
  }

  public enum Kind {
    EXACT,
    CARET,
    TILDE
  }
}
