package com.typeobject.wheeler.tools;

/** Shared renderer-independent heading identity rules for documentation producers. */
final class DocumentationAnchors {
  private DocumentationAnchors() {}

  /** Converts one heading title or anchor spelling to its canonical stable fragment. */
  static String canonical(String title) {
    StringBuilder result = new StringBuilder();
    boolean separator = false;
    for (int codePoint : title.toLowerCase(java.util.Locale.ROOT).codePoints().toArray()) {
      if (Character.isLetterOrDigit(codePoint) || codePoint == '_') {
        if (separator && !result.isEmpty() && result.charAt(result.length() - 1) != '-') {
          result.append('-');
        }
        separator = false;
        result.appendCodePoint(codePoint);
      } else if (Character.isWhitespace(codePoint) || codePoint == '-') {
        separator = true;
      }
    }
    return result.toString();
  }
}
