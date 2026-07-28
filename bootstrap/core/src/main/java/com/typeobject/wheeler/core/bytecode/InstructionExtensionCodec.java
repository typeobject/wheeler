package com.typeobject.wheeler.core.bytecode;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Canonical required-instruction-extension metadata. */
final class InstructionExtensionCodec {
  private static final int MAX_EXTENSIONS = 64;
  private static final int MAX_NAME_BYTES = 128;
  private static final Set<String> SUPPORTED = Set.of();

  private InstructionExtensionCodec() {}

  static byte[] write(List<String> extensions) {
    validate(extensions);
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeUnsigned(output, extensions.size());
    for (String extension : extensions) {
      byte[] name = extension.getBytes(StandardCharsets.US_ASCII);
      writeUnsigned(output, name.length);
      output.writeBytes(name);
    }
    return output.toByteArray();
  }

  static List<String> read(ByteBuffer input) {
    input.order(ByteOrder.LITTLE_ENDIAN);
    if (input.remaining() < Integer.BYTES) {
      throw new BytecodeException("Truncated instruction-extension count");
    }
    int count = input.getInt();
    if (count <= 0 || count > MAX_EXTENSIONS) {
      throw new BytecodeException("Invalid instruction-extension count " + count);
    }
    List<String> extensions = new ArrayList<>(count);
    for (int index = 0; index < count; index++) {
      if (input.remaining() < Integer.BYTES) {
        throw new BytecodeException("Truncated instruction-extension name length");
      }
      int length = input.getInt();
      if (length <= 0 || length > MAX_NAME_BYTES || length > input.remaining()) {
        throw new BytecodeException("Invalid instruction-extension name length " + length);
      }
      byte[] name = new byte[length];
      input.get(name);
      extensions.add(new String(name, StandardCharsets.US_ASCII));
    }
    if (input.hasRemaining()) {
      throw new BytecodeException("Trailing instruction-extension metadata");
    }
    validate(extensions);
    return List.copyOf(extensions);
  }

  static void validate(List<String> extensions) {
    if (extensions.size() > MAX_EXTENSIONS) {
      throw new BytecodeException("Too many required instruction extensions");
    }
    String previous = null;
    for (String extension : extensions) {
      validateName(extension);
      if (previous != null && previous.compareTo(extension) >= 0) {
        throw new BytecodeException("Instruction extensions are not unique and sorted");
      }
      previous = extension;
    }
  }

  static void requireSupported(List<String> extensions) {
    for (String extension : extensions) {
      if (!SUPPORTED.contains(extension)) {
        throw new BytecodeException("Unsupported required instruction extension " + extension);
      }
    }
  }

  private static void validateName(String extension) {
    byte[] bytes = extension.getBytes(StandardCharsets.US_ASCII);
    if (extension.isEmpty() || bytes.length > MAX_NAME_BYTES
        || !extension.equals(new String(bytes, StandardCharsets.US_ASCII))) {
      throw new BytecodeException("Invalid instruction-extension name " + extension);
    }
    int slash = extension.indexOf('/');
    if (slash <= 0 || slash != extension.lastIndexOf('/') || slash == extension.length() - 1) {
      throw new BytecodeException("Invalid instruction-extension name " + extension);
    }
    for (int index = 0; index < slash; index++) {
      char value = extension.charAt(index);
      if (!asciiLower(value) && !asciiDigit(value) && value != '.' && value != '-') {
        throw new BytecodeException("Invalid instruction-extension name " + extension);
      }
    }
    for (int index = slash + 1; index < extension.length(); index++) {
      if (!asciiDigit(extension.charAt(index))) {
        throw new BytecodeException("Invalid instruction-extension version " + extension);
      }
    }
    if (extension.charAt(slash + 1) == '0') {
      throw new BytecodeException("Noncanonical instruction-extension version " + extension);
    }
  }

  private static boolean asciiLower(char value) {
    return 'a' <= value && value <= 'z';
  }

  private static boolean asciiDigit(char value) {
    return '0' <= value && value <= '9';
  }

  private static void writeUnsigned(ByteArrayOutputStream output, int value) {
    for (int octet = 0; octet < Integer.BYTES; octet++) {
      output.write(value >>> (octet * Byte.SIZE));
    }
  }
}
