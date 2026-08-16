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

  static long unsigned(byte[] bytes, int offset, int width) {
    long value = 0;
    for (int index = width - 1; index >= 0; index--) {
      value = value * 256 + Byte.toUnsignedInt(bytes[offset + index]);
    }
    return value;
  }
}
