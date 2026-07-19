package com.typeobject.wheeler.core.vm;

/** A deterministic program trap. The failing instruction leaves machine data unchanged. */
public final class VmTrap extends RuntimeException {
  private static final long serialVersionUID = 1L;
  private final Code code;

  public VmTrap(String message) {
    this(Code.RUNTIME, message);
  }

  public VmTrap(Code code, String message) {
    super(message);
    this.code = java.util.Objects.requireNonNull(code, "code");
  }

  public Code code() {
    return code;
  }

  /** Stable semantic trap families exposed to the test runner. */
  public enum Code {
    RUNTIME,
    ASSERTION
  }
}
