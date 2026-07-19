package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.regex.Pattern;

/** Canonical source-affecting options shared by every bootstrap derivation. */
public record BootstrapCompilerOptions(String profile, boolean sourceMaps) {
  public static final int SCHEMA_VERSION = 1;
  public static final String FILE_NAME = "wheeler.compiler-options.yaml";
  private static final Pattern PROFILE = Pattern.compile("[A-Za-z0-9][A-Za-z0-9._-]{0,127}");

  public BootstrapCompilerOptions {
    if (profile == null || !PROFILE.matcher(profile).matches()) {
      throw new PackageFormatException("Invalid bootstrap compiler profile");
    }
  }

  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "compiler:\n"
        + "  profile: " + CanonicalYaml.quote(profile) + "\n"
        + "  source-maps: " + sourceMaps + "\n";
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
}
