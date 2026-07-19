package com.typeobject.wheeler.packageformat;

/** Malformed, noncanonical, or integrity-invalid Wheeler package data. */
public final class PackageFormatException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public PackageFormatException(String message) {
    super(message);
  }

  public PackageFormatException(String message, Throwable cause) {
    super(message, cause);
  }
}
