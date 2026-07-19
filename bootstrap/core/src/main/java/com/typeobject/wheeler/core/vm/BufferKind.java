package com.typeobject.wheeler.core.vm;

/** Element representation and allocation charge for one owned buffer. */
public enum BufferKind {
  WORDS(Long.BYTES, Long.MIN_VALUE, Long.MAX_VALUE, 1),
  BYTES(Byte.BYTES, 0, 255, 1),
  UTF8(Byte.BYTES, 0, 255, 1),
  LONG_MAP(3 * Long.BYTES, Long.MIN_VALUE, Long.MAX_VALUE, 3);

  private final int elementBytes;
  private final long minimum;
  private final long maximum;
  private final int storageWords;

  BufferKind(int elementBytes, long minimum, long maximum, int storageWords) {
    this.elementBytes = elementBytes;
    this.minimum = minimum;
    this.maximum = maximum;
    this.storageWords = storageWords;
  }

  int elementBytes() {
    return elementBytes;
  }

  int storageSlots(int length) {
    return Math.multiplyExact(length, storageWords);
  }

  boolean accepts(long value) {
    return value >= minimum && value <= maximum;
  }
}
