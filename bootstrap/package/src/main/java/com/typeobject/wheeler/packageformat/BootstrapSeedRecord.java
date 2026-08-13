package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.regex.Pattern;

/** Canonical source-correspondence record for one bootstrap artifact. */
public record BootstrapSeedRecord(
    Kind kind,
    String artifact,
    String platform,
    String output,
    int outputLength,
    String sourceRevision,
    String source,
    String buildCommand,
    String workingDirectory,
    String builder,
    List<String> dependencies,
    String environment,
    String parent,
    List<String> attestations,
    String origin,
    String transport,
    String acquired,
    String reason) {
  public static final String FILE_NAME = "wheeler.seed.yaml";
  public static final int SCHEMA_VERSION = 1;
  private static final Pattern KEYWORD = Pattern.compile("[a-z0-9][a-z0-9._+-]{0,127}");
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");
  private static final int MAX_TEXT_LENGTH = 16_384;

  public BootstrapSeedRecord {
    if (kind == null) {
      throw new PackageFormatException("Bootstrap seed kind is required");
    }
    artifact = keyword(artifact, "seed artifact");
    platform = keyword(platform, "seed platform");
    output = identity(output, "seed output");
    if (outputLength < 1) {
      throw new PackageFormatException("Bootstrap seed output length must be positive");
    }
    sourceRevision = text(sourceRevision, "source revision", kind == Kind.OPAQUE_ROOT);
    source = optionalIdentity(source, "seed source", kind == Kind.OPAQUE_ROOT);
    buildCommand = text(buildCommand, "build command", false);
    workingDirectory = text(workingDirectory, "working directory", false);
    builder = identity(builder, "seed builder");
    dependencies = identities(dependencies, "seed dependency");
    environment = identity(environment, "seed environment");
    parent = optionalIdentity(parent, "parent seed", true);
    attestations = identities(attestations, "seed attestation");
    origin = text(origin, "opaque origin", kind != Kind.OPAQUE_ROOT);
    transport = optionalIdentity(transport, "opaque transport", kind != Kind.OPAQUE_ROOT);
    acquired = text(acquired, "opaque acquisition date", kind != Kind.OPAQUE_ROOT);
    reason = text(reason, "opaque reason", kind != Kind.OPAQUE_ROOT);
    validateClassification(
        kind, sourceRevision, source, parent, origin, transport, acquired, reason);
  }

  public boolean opaque() {
    return kind == Kind.OPAQUE_ROOT;
  }

  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "seed:\n"
        + field("kind", kind.keyword())
        + field("artifact", artifact)
        + field("platform", platform)
        + field("output", output)
        + "  output-length: " + outputLength + "\n"
        + field("source-revision", sourceRevision)
        + field("source", source)
        + field("build-command", buildCommand)
        + field("working-directory", workingDirectory)
        + field("builder", builder)
        + sequence("dependencies", dependencies)
        + field("environment", environment)
        + field("parent", parent)
        + sequence("attestations", attestations)
        + "  opaque: " + opaque() + "\n"
        + field("origin", origin)
        + field("transport", transport)
        + field("acquired", acquired)
        + field("reason", reason);
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

  private static String field(String name, String value) {
    return "  " + name + ": " + CanonicalYaml.quote(value) + "\n";
  }

  private static String sequence(String name, List<String> values) {
    if (values.isEmpty()) {
      return "  " + name + ": []\n";
    }
    StringBuilder result = new StringBuilder("  ").append(name).append(":\n");
    for (String value : values) {
      result.append("    - ").append(CanonicalYaml.quote(value)).append('\n');
    }
    return result.toString();
  }

  private static void validateClassification(
      Kind kind,
      String sourceRevision,
      String source,
      String parent,
      String origin,
      String transport,
      String acquired,
      String reason) {
    if (kind == Kind.OPAQUE_ROOT) {
      if (!sourceRevision.isEmpty() || !source.isEmpty() || !parent.isEmpty()) {
        throw new PackageFormatException(
            "Opaque roots cannot claim source correspondence or a parent seed");
      }
      if (origin.isEmpty() || transport.isEmpty() || acquired.isEmpty() || reason.isEmpty()) {
        throw new PackageFormatException("Opaque roots require complete acquisition metadata");
      }
      return;
    }
    if (sourceRevision.isEmpty() || source.isEmpty()) {
      throw new PackageFormatException("Reproducible seeds require source correspondence");
    }
    if (!origin.isEmpty() || !transport.isEmpty() || !acquired.isEmpty() || !reason.isEmpty()) {
      throw new PackageFormatException(
          "Reproducible seeds cannot carry opaque-root acquisition metadata");
    }
  }

  private static String keyword(String value, String description) {
    if (value == null || !KEYWORD.matcher(value).matches()) {
      throw new PackageFormatException("Invalid keyword for " + description);
    }
    return value;
  }

  private static String identity(String value, String description) {
    if (value == null || !IDENTITY.matcher(value).matches()) {
      throw new PackageFormatException("Invalid SHA-256 identity for " + description);
    }
    return value;
  }

  private static String optionalIdentity(
      String value, String description, boolean emptyAllowed) {
    if (value == null) {
      throw new PackageFormatException("Missing " + description);
    }
    if (value.isEmpty() && emptyAllowed) {
      return value;
    }
    return identity(value, description);
  }

  private static List<String> identities(List<String> values, String description) {
    if (values == null) {
      throw new PackageFormatException("Missing " + description + " list");
    }
    List<String> copy = List.copyOf(values);
    for (String value : copy) {
      identity(value, description);
    }
    if (copy.stream().distinct().count() != copy.size()) {
      throw new PackageFormatException("Duplicate " + description + " identity");
    }
    return copy;
  }

  private static String text(String value, String description, boolean emptyAllowed) {
    if (value == null || value.length() > MAX_TEXT_LENGTH || (!emptyAllowed && value.isEmpty())) {
      throw new PackageFormatException("Invalid " + description);
    }
    return value;
  }

  /** Bootstrap seed classes; the class does not by itself prove source correspondence. */
  public enum Kind {
    ALTERNATE_STAGE0("alternate-stage0"),
    RECOVERY_RELEASE("recovery-release"),
    SYSTEM_TOOLCHAIN("system-toolchain"),
    OPAQUE_ROOT("opaque-root");

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
      throw new PackageFormatException("Unknown bootstrap seed kind " + keyword);
    }
  }
}
