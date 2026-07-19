package com.typeobject.wheeler.runtime.hybrid;

/** Integrity, lifecycle, or persistence failure in a hybrid run. */
public final class HybridRunException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public HybridRunException(String message) {
    super(message);
  }

  public HybridRunException(String message, Throwable cause) {
    super(message, cause);
  }
}
