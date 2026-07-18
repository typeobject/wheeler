package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.List;

/** Immutable control frame with verified signed-64 local registers. */
public record Frame(
    int functionId, boolean inverse, int programCounter, List<Long> locals) {
  public Frame {
    if (functionId < 0 || programCounter < 0) {
      throw new IllegalArgumentException("Invalid frame");
    }
    locals = List.copyOf(locals);
  }

  public static Frame create(int functionId, boolean inverse, int localCount) {
    if (localCount < 0) {
      throw new IllegalArgumentException("Invalid local count");
    }
    return new Frame(
        functionId, inverse, 0, new ArrayList<>(java.util.Collections.nCopies(localCount, 0L)));
  }

  public Frame advance() {
    return jump(Math.addExact(programCounter, 1));
  }

  public Frame jump(int target) {
    return new Frame(functionId, inverse, target, locals);
  }

  public long local(int index) {
    return locals.get(index);
  }

  public Frame withLocal(int index, long value) {
    ArrayList<Long> updated = new ArrayList<>(locals);
    updated.set(index, value);
    return new Frame(functionId, inverse, programCounter, updated);
  }
}
