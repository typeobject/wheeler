package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.regex.Pattern;

/** Canonical provenance closure for one compiler-toolchain derivation. */
public record BootstrapToolchain(
    Kind kind,
    String source,
    String builder,
    String dependencies,
    String environment) {
  public static final int SCHEMA_VERSION = 1;
  public static final String FILE_NAME = "wheeler.toolchain.yaml";
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");

  public BootstrapToolchain {
    if (kind == null) {
      throw new PackageFormatException("Bootstrap toolchain kind is required");
    }
    source = identity(source, "toolchain source");
    builder = identity(builder, "toolchain builder");
    dependencies = identity(dependencies, "toolchain dependencies");
    environment = identity(environment, "toolchain environment");
  }

  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "toolchain:\n"
        + "  kind: " + CanonicalYaml.quote(kind.keyword()) + "\n"
        + "  source: " + CanonicalYaml.quote(source) + "\n"
        + "  builder: " + CanonicalYaml.quote(builder) + "\n"
        + "  dependencies: " + CanonicalYaml.quote(dependencies) + "\n"
        + "  environment: " + CanonicalYaml.quote(environment) + "\n";
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  public String identity() {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(canonicalBytes()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String identity(String value, String description) {
    if (value == null || !IDENTITY.matcher(value).matches()) {
      throw new PackageFormatException("Invalid SHA-256 identity for " + description);
    }
    return value;
  }

  /** Auditable trusted derivation categories; labels alone establish no diversity. */
  public enum Kind {
    RECOVERY_SEED("recovery-seed"),
    INDEPENDENT_STAGE0("independent-stage0"),
    HOST_SOURCE("host-source");

    private final String keyword;

    Kind(String keyword) {
      this.keyword = keyword;
    }

    public String keyword() {
      return keyword;
    }

    public static Kind fromKeyword(String keyword) {
      for (Kind candidate : values()) {
        if (candidate.keyword.equals(keyword)) {
          return candidate;
        }
      }
      throw new PackageFormatException("Unknown bootstrap toolchain kind " + keyword);
    }
  }
}
