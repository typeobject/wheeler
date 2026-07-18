package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.List;

/** Immutable control frame with verified signed-64 local registers. */
public record Frame(
    int functionId,
    boolean inverse,
    int programCounter,
    int returnDestination,
    List<Long> locals) {
  public Frame {
    if (functionId < 0 || programCounter < 0 || returnDestination < -1) {
      throw new IllegalArgumentException("Invalid frame");
    }
    locals = List.copyOf(locals);
  }

  public static Frame create(int functionId, boolean inverse, int localCount) {
    return create(functionId, inverse, localCount, -1, List.of());
  }

  public static Frame create(
      int functionId,
      boolean inverse,
      int localCount,
      int returnDestination,
      List<Long> arguments) {
    if (localCount < 0 || arguments.size() > localCount) {
      throw new IllegalArgumentException("Invalid frame signature");
    }
    ArrayList<Long> locals = new ArrayList<>(java.util.Collections.nCopies(localCount, 0L));
    for (int index = 0; index < arguments.size(); index++) {
      locals.set(index, arguments.get(index));
    }
    return new Frame(functionId, inverse, 0, returnDestination, locals);
  }

  public Frame advance() {
    return jump(Math.addExact(programCounter, 1));
  }

  public Frame jump(int target) {
    return new Frame(functionId, inverse, target, returnDestination, locals);
  }

  public long local(int index) {
    return locals.get(index);
  }

  public Frame withLocal(int index, long value) {
    ArrayList<Long> updated = new ArrayList<>(locals);
    updated.set(index, value);
    return new Frame(functionId, inverse, programCounter, returnDestination, updated);
  }
}
