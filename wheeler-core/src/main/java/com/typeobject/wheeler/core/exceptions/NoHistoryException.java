package com.typeobject.wheeler.core.exceptions;

public class NoHistoryException extends WheelerExecutionException {
  public NoHistoryException(String message) {
    super(message);
  }

  public NoHistoryException(long threadId) {
    super("No history available for thread " + threadId);
  }

  public NoHistoryException(String message, Throwable cause) {
    super(message, cause);
  }
}
