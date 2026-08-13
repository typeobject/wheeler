package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.regex.Pattern;

/** Canonical release evidence binding a complete seed chain and opaque-root inventory. */
public record BootstrapRecoveryEvidence(
    String seedChain,
    int seedCount,
    int opaqueCount,
    int opaqueBytes,
    List<String> opaqueRoots,
    String sourceArchive,
    String lock,
    String compilerOptions,
    String compilerLimits,
    String fixedPoint,
    String diverseCompilation,
    String acceptanceArtifacts,
    String parentRecovery) {
  public static final String FILE_NAME = "wheeler.recovery.yaml";
  public static final int SCHEMA_VERSION = 1;
  private static final Pattern IDENTITY = Pattern.compile("[0-9a-f]{64}");

  public BootstrapRecoveryEvidence {
    seedChain = identity(seedChain, "recovery seed chain");
    if (seedCount < 1) {
      throw new PackageFormatException("Recovery evidence requires at least one seed");
    }
    if (opaqueCount < 0 || opaqueBytes < 0) {
      throw new PackageFormatException("Recovery opaque-root totals cannot be negative");
    }
    if (opaqueRoots == null) {
      throw new PackageFormatException("Recovery opaque-root inventory is required");
    }
    opaqueRoots = List.copyOf(opaqueRoots);
    for (String root : opaqueRoots) {
      identity(root, "recovery opaque root");
    }
    if (opaqueRoots.stream().distinct().count() != opaqueRoots.size()) {
      throw new PackageFormatException("Recovery opaque-root inventory contains duplicates");
    }
    if (opaqueRoots.size() != opaqueCount) {
      throw new PackageFormatException("Recovery opaque-root count does not match its inventory");
    }
    sourceArchive = identity(sourceArchive, "recovery source archive");
    lock = identity(lock, "recovery lock");
    compilerOptions = identity(compilerOptions, "recovery compiler options");
    compilerLimits = identity(compilerLimits, "recovery compiler limits");
    fixedPoint = identity(fixedPoint, "recovery fixed-point evidence");
    diverseCompilation = identity(diverseCompilation, "recovery diverse evidence");
    acceptanceArtifacts = identity(acceptanceArtifacts, "recovery acceptance artifacts");
    parentRecovery = optionalIdentity(parentRecovery, "parent recovery release");
  }

  public static BootstrapRecoveryEvidence fromChain(
      BootstrapSeedChain chain,
      String sourceArchive,
      String lock,
      String compilerOptions,
      String compilerLimits,
      String fixedPoint,
      String diverseCompilation,
      String acceptanceArtifacts,
      String parentRecovery) {
    List<BootstrapSeedRecord> opaque = chain.records().stream()
        .filter(BootstrapSeedRecord::opaque)
        .toList();
    int opaqueBytes = 0;
    for (BootstrapSeedRecord root : opaque) {
      try {
        opaqueBytes = Math.addExact(opaqueBytes, root.outputLength());
      } catch (ArithmeticException exception) {
        throw new PackageFormatException("Recovery opaque-root byte total overflows", exception);
      }
    }
    return new BootstrapRecoveryEvidence(
        chain.identity(),
        chain.records().size(),
        opaque.size(),
        opaqueBytes,
        opaque.stream().map(BootstrapSeedRecord::identity).sorted().toList(),
        sourceArchive,
        lock,
        compilerOptions,
        compilerLimits,
        fixedPoint,
        diverseCompilation,
        acceptanceArtifacts,
        parentRecovery);
  }

  public void validate(BootstrapSeedChain chain) {
    BootstrapRecoveryEvidence expected = fromChain(
        chain,
        sourceArchive,
        lock,
        compilerOptions,
        compilerLimits,
        fixedPoint,
        diverseCompilation,
        acceptanceArtifacts,
        parentRecovery);
    if (!equals(expected)) {
      throw new PackageFormatException(
          "Recovery evidence does not bind the supplied seed chain and opaque-root inventory");
    }
  }

  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "recovery:\n"
        + field("seed-chain", seedChain)
        + "  seed-count: " + seedCount + "\n"
        + "  opaque-count: " + opaqueCount + "\n"
        + "  opaque-bytes: " + opaqueBytes + "\n"
        + sequence("opaque-roots", opaqueRoots)
        + field("source-archive", sourceArchive)
        + field("lock", lock)
        + field("compiler-options", compilerOptions)
        + field("compiler-limits", compilerLimits)
        + field("fixed-point", fixedPoint)
        + field("diverse-compilation", diverseCompilation)
        + field("acceptance-artifacts", acceptanceArtifacts)
        + field("parent-recovery", parentRecovery);
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

  private static String identity(String value, String description) {
    if (value == null || !IDENTITY.matcher(value).matches()) {
      throw new PackageFormatException("Invalid SHA-256 identity for " + description);
    }
    return value;
  }

  private static String optionalIdentity(String value, String description) {
    if (value == null) {
      throw new PackageFormatException("Missing " + description);
    }
    if (value.isEmpty()) {
      return value;
    }
    return identity(value, description);
  }
}
