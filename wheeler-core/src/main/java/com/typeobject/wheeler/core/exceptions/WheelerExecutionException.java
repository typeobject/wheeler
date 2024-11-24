package com.typeobject.wheeler.core.exceptions;

public class WheelerExecutionException extends RuntimeException {
    public WheelerExecutionException(String message) {
        super(message);
    }

    public WheelerExecutionException(String message, Throwable cause) {
        super(message, cause);
    }
}
