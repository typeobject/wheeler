package com.typeobject.wheeler.examples;

/** Balanced source-range helpers for native compiler fixtures. */
final class SourceRanges {
  private SourceRanges() {}

  static int matchingClose(String source, int open) {
    int depth = 1;
    for (int cursor = open + 1; cursor < source.length(); cursor++) {
      if (source.charAt(cursor) == '{') {
        depth++;
      } else if (source.charAt(cursor) == '}' && --depth == 0) {
        return cursor;
      }
    }
    throw new IllegalArgumentException("unclosed source range");
  }
}
