package com.typeobject.wheeler.core.vm;

/** Immutable control frame. Program counters index verified decoded instructions. */
public record Frame(int functionId, boolean inverse, int programCounter) {
  public Frame {
    if (functionId < 0 || programCounter < 0) {
      throw new IllegalArgumentException("Invalid frame");
    }
  }

  public Frame advance() {
    return new Frame(functionId, inverse, Math.addExact(programCounter, 1));
  }
}
