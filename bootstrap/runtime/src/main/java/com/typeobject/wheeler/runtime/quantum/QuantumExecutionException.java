package com.typeobject.wheeler.runtime.quantum;

/** Stable runtime failure at a quantum target boundary. */
public final class QuantumExecutionException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public QuantumExecutionException(String message) {
    super(message);
  }
}
