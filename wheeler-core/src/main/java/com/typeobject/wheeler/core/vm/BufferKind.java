package com.typeobject.wheeler.core.vm;

/** Element representation and allocation charge for one owned buffer. */
public enum BufferKind {
  WORDS(Long.BYTES, Long.MIN_VALUE, Long.MAX_VALUE),
  BYTES(Byte.BYTES, 0, 255);

  private final int elementBytes;
  private final long minimum;
  private final long maximum;

  BufferKind(int elementBytes, long minimum, long maximum) {
    this.elementBytes = elementBytes;
    this.minimum = minimum;
    this.maximum = maximum;
  }

  int elementBytes() {
    return elementBytes;
  }

  boolean accepts(long value) {
    return value >= minimum && value <= maximum;
  }
}
