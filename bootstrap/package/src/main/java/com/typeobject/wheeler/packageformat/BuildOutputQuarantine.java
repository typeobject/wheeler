package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;

/** Deterministic evidence that one build input produced conflicting verified bytes. */
public record BuildOutputQuarantine(
    String buildInputIdentity,
    String expectedPrev,
    String observedPrev,
    long observedBytes) {
  public static final int SCHEMA_VERSION = 1;
  public static final String FILE_NAME = "quarantine.yaml";

  public BuildOutputQuarantine {
    if (!hash(buildInputIdentity) || !hash(expectedPrev) || !hash(observedPrev)
        || expectedPrev.equals(observedPrev)
        || observedBytes <= 0 || observedBytes > 16L * 1024 * 1024) {
      throw new PackageFormatException("Invalid divergent build-output quarantine record");
    }
  }

  public String canonicalText() {
    return "schema: 1\n"
        + "build-input: " + quote(buildInputIdentity) + "\n"
        + "expected-prev: " + quote(expectedPrev) + "\n"
        + "observed-prev: " + quote(observedPrev) + "\n"
        + "observed-bytes: " + observedBytes + "\n";
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  private static String quote(String value) {
    return CanonicalYaml.quote(value);
  }

  private static boolean hash(String value) {
    return value != null && value.matches("[0-9a-f]{64}");
  }
}
