package com.typeobject.wheeler.core.vm;

/** A deterministic program trap. The failing instruction leaves machine data unchanged. */
public final class VmTrap extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public VmTrap(String message) {
    super(message);
  }
}
