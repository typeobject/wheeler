package com.typeobject.wheeler.core.vm;

import java.util.List;

/** Strict RFC 3629 UTF-8 validation and scalar counting over canonical byte values. */
final class Utf8 {
  record Analysis(boolean valid, long scalarCount) {}

  private Utf8() {}

  static Analysis analyze(List<Long> values) {
    long scalars = 0;
    for (int index = 0; index < values.size(); scalars++) {
      int first = byteAt(values, index++);
      if (first <= 0x7f) {
        continue;
      }
      if (first >= 0xc2 && first <= 0xdf) {
        if (!continuation(values, index)) {
          return new Analysis(false, 0);
        }
        index++;
        continue;
      }
      if (first >= 0xe0 && first <= 0xef) {
        if (index + 1 >= values.size()) {
          return new Analysis(false, 0);
        }
        int second = byteAt(values, index);
        boolean legalSecond = first == 0xe0
            ? second >= 0xa0 && second <= 0xbf
            : first == 0xed
                ? second >= 0x80 && second <= 0x9f
                : second >= 0x80 && second <= 0xbf;
        if (!legalSecond || !continuation(values, index + 1)) {
          return new Analysis(false, 0);
        }
        index += 2;
        continue;
      }
      if (first >= 0xf0 && first <= 0xf4) {
        if (index + 2 >= values.size()) {
          return new Analysis(false, 0);
        }
        int second = byteAt(values, index);
        boolean legalSecond = first == 0xf0
            ? second >= 0x90 && second <= 0xbf
            : first == 0xf4
                ? second >= 0x80 && second <= 0x8f
                : second >= 0x80 && second <= 0xbf;
        if (!legalSecond
            || !continuation(values, index + 1)
            || !continuation(values, index + 2)) {
          return new Analysis(false, 0);
        }
        index += 3;
        continue;
      }
      return new Analysis(false, 0);
    }
    return new Analysis(true, scalars);
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
