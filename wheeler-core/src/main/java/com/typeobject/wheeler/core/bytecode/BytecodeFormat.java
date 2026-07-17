package com.typeobject.wheeler.core.bytecode;

import java.nio.charset.StandardCharsets;

/** Constants for the Wheeler Bytecode Container version 1. */
public final class BytecodeFormat {
  public static final byte[] MAGIC = "WHEELBC\0".getBytes(StandardCharsets.US_ASCII);
  public static final int MAJOR_VERSION = 1;
  public static final int MINOR_VERSION = 0;
  public static final int HEADER_SIZE = 40;
  public static final int DIRECTORY_ENTRY_SIZE = 32;
  public static final int REQUIRED_SECTION = 1;
  public static final int MAX_ARTIFACT_BYTES = 16 * 1024 * 1024;

  public static final int MANIFEST = 1;
  public static final int STRINGS = 2;
  public static final int TYPES = 3;
  public static final int FUNCTIONS = 5;
  public static final int CODE = 6;
  public static final int WORKFLOW = 7;
  public static final int QUANTUM = 8;

  private BytecodeFormat() {}

  public static int align8(int value) {
    return Math.addExact(value, 7) & ~7;
  }
}
