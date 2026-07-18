package com.typeobject.wheeler.core.vm;

import java.util.List;
import java.util.Objects;

/** Immutable control frame backed by persistent chunked signed-64 registers. */
public final class Frame {
  private final int functionId;
  private final boolean inverse;
  private final int programCounter;
  private final int returnDestination;
  private final LocalRegisters locals;

  public Frame(
      int functionId,
      boolean inverse,
      int programCounter,
      int returnDestination,
      List<Long> locals) {
    this(
        functionId,
        inverse,
        programCounter,
        returnDestination,
        LocalRegisters.create(locals.size(), locals));
  }

  private Frame(
      int functionId,
      boolean inverse,
      int programCounter,
      int returnDestination,
      LocalRegisters locals) {
    if (functionId < 0 || programCounter < 0 || returnDestination < -1) {
      throw new IllegalArgumentException("Invalid frame");
    }
    this.functionId = functionId;
    this.inverse = inverse;
    this.programCounter = programCounter;
    this.returnDestination = returnDestination;
    this.locals = Objects.requireNonNull(locals, "locals");
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
    return new Frame(
        functionId,
        inverse,
        0,
        returnDestination,
        LocalRegisters.create(localCount, arguments));
  }

  public int functionId() {
    return functionId;
  }

  public boolean inverse() {
    return inverse;
  }

  public int programCounter() {
    return programCounter;
  }

  public int returnDestination() {
    return returnDestination;
  }

  public int localCount() {
    return locals.size();
  }

  public List<Long> locals() {
    return locals.asList();
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
    return new Frame(
        functionId,
        inverse,
        programCounter,
        returnDestination,
        locals.with(index, value));
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    if (!(other instanceof Frame frame)) {
      return false;
    }
    return functionId == frame.functionId
        && inverse == frame.inverse
        && programCounter == frame.programCounter
        && returnDestination == frame.returnDestination
        && locals.equals(frame.locals);
  }

  @Override
  public int hashCode() {
    return Objects.hash(functionId, inverse, programCounter, returnDestination, locals);
  }

  @Override
  public String toString() {
    return "Frame[functionId=" + functionId
        + ", inverse=" + inverse
        + ", programCounter=" + programCounter
        + ", returnDestination=" + returnDestination
        + ", locals=" + locals.asList() + "]";
  }
}
