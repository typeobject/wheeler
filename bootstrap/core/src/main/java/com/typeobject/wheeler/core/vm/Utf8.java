package com.typeobject.wheeler.core.vm;

import java.util.List;

/** Strict RFC 3629 UTF-8 decoding over canonical byte values. */
final class Utf8 {
  record Analysis(boolean valid, long scalarCount) {}
  record Scalar(boolean valid, long value, int width) {}

  private static final Scalar INVALID = new Scalar(false, 0, 0);

  private Utf8() {}

  static Analysis analyze(List<Long> values) {
    long count = 0;
    int index = 0;
    while (index < values.size()) {
      Scalar scalar = decode(values, index);
      if (!scalar.valid()) {
        return new Analysis(false, 0);
      }
      index += scalar.width();
      count++;
    }
    return new Analysis(true, count);
  }

  static Scalar decode(List<Long> values, int index) {
    if (index < 0 || index >= values.size()) {
      return INVALID;
    }
    int first = byteAt(values, index);
    if (first <= 0x7f) {
      return new Scalar(true, first, 1);
    }
    if (first >= 0xc2 && first <= 0xdf) {
      if (!continuation(values, index + 1)) {
        return INVALID;
      }
      long value = ((first & 0x1fL) << 6) | (byteAt(values, index + 1) & 0x3fL);
      return new Scalar(true, value, 2);
    }
    if (first >= 0xe0 && first <= 0xef) {
      if (index + 2 >= values.size()) {
        return INVALID;
      }
      int second = byteAt(values, index + 1);
      boolean legalSecond = first == 0xe0
          ? second >= 0xa0 && second <= 0xbf
          : first == 0xed
              ? second >= 0x80 && second <= 0x9f
              : second >= 0x80 && second <= 0xbf;
      if (!legalSecond || !continuation(values, index + 2)) {
        return INVALID;
      }
      long value = ((first & 0x0fL) << 12)
          | ((second & 0x3fL) << 6)
          | (byteAt(values, index + 2) & 0x3fL);
      return new Scalar(true, value, 3);
    }
    if (first >= 0xf0 && first <= 0xf4) {
      if (index + 3 >= values.size()) {
        return INVALID;
      }
      int second = byteAt(values, index + 1);
      boolean legalSecond = first == 0xf0
          ? second >= 0x90 && second <= 0xbf
          : first == 0xf4
              ? second >= 0x80 && second <= 0x8f
              : second >= 0x80 && second <= 0xbf;
      if (!legalSecond
          || !continuation(values, index + 2)
          || !continuation(values, index + 3)) {
        return INVALID;
      }
      long value = ((first & 0x07L) << 18)
          | ((second & 0x3fL) << 12)
          | ((byteAt(values, index + 2) & 0x3fL) << 6)
          | (byteAt(values, index + 3) & 0x3fL);
      return new Scalar(true, value, 4);
    }
    return INVALID;
  }

  private static boolean continuation(List<Long> values, int index) {
    if (index >= values.size()) {
      return false;
    }
    int value = byteAt(values, index);
    return value >= 0x80 && value <= 0xbf;
  }

  private static int byteAt(List<Long> values, int index) {
    return Math.toIntExact(values.get(index));
  }
}
