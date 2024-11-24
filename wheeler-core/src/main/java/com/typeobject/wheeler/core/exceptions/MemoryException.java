package com.typeobject.wheeler.core.exceptions;

public class MemoryException extends WheelerExecutionException {
  public MemoryException(String message) {
    super(message);
  }

  public MemoryException(String message, Throwable cause) {
    super(message, cause);
  }

  public MemoryException(long address) {
    super("Invalid memory access at address: 0x" + Long.toHexString(address));
  }
}
