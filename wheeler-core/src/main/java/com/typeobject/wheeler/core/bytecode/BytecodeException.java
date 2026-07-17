package com.typeobject.wheeler.core.bytecode;

/** Indicates malformed or semantically invalid Wheeler bytecode. */
public final class BytecodeException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public BytecodeException(String message) {
    super(message);
  }

  public BytecodeException(String message, Throwable cause) {
    super(message, cause);
  }
}
