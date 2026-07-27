package com.typeobject.wheeler.runtime.io;

import java.util.Objects;

/** Exact protected generation and byte range named by durability evidence. */
public record DurabilitySubject(
    String resourceIdentity,
    long generation,
    long offset,
    long length,
    String contentIdentity,
    String namespaceIdentity) {
  public DurabilitySubject {
    resourceIdentity = visibleAscii("resourceIdentity", resourceIdentity, 256, false);
    if (generation < 0 || offset < 0 || length < 0 || Long.MAX_VALUE - offset < length) {
      throw new IllegalArgumentException("durability subject range is invalid");
    }
    contentIdentity = sha256("contentIdentity", contentIdentity);
    namespaceIdentity = visibleAscii("namespaceIdentity", namespaceIdentity, 256, true);
  }

  boolean hasNamespace() {
    return !namespaceIdentity.equals("-");
  }

  static String visibleAscii(String name, String value, int maximum, boolean absentAllowed) {
    Objects.requireNonNull(value, name);
    if (absentAllowed && value.equals("-")) {
      return value;
    }
    if (value.isBlank() || value.length() > maximum || !value.equals(value.trim())) {
      throw new IllegalArgumentException(name + " must be bounded canonical visible ASCII");
    }
    for (int index = 0; index < value.length(); index++) {
      char character = value.charAt(index);
      if (character < 0x21 || character > 0x7e) {
        throw new IllegalArgumentException(name + " must use visible ASCII");
      }
    }
    return value;
  }

  static String sha256(String name, String value) {
    Objects.requireNonNull(value, name);
    if (value.length() != 64) {
      throw new IllegalArgumentException(name + " must be lowercase SHA-256");
    }
    for (int index = 0; index < value.length(); index++) {
      char character = value.charAt(index);
      if (!((character >= '0' && character <= '9')
          || (character >= 'a' && character <= 'f'))) {
        throw new IllegalArgumentException(name + " must be lowercase SHA-256");
      }
    }
    return value;
  }
}
