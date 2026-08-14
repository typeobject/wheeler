package com.typeobject.wheeler.packageformat;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;

/** Verifies one package output against its archive, lock, plan, source, and toolchain closure. */
public final class PackageProvenanceVerifier {
  private static final String DOMAIN = "wheeler.package-provenance.v1";
  private static final int MAX_OUTPUT_BYTES = 16 * 1024 * 1024;

  private PackageProvenanceVerifier() {}

  /** Exact output identity and length admitted by a release or repository record. */
  public record OutputExpectation(String identity, long length) {
    /** Requires one bounded nonempty output and its canonical SHA-256 identity. */
    public OutputExpectation {
      requireIdentity(identity, "expected output identity");
      if (length < 1 || MAX_OUTPUT_BYTES < length) {
        throw new PackageFormatException("Expected package output length is invalid");
      }
    }
  }

  /** Complete canonical identities accepted for one package-target output. */
  public record Evidence(
      String packageArchiveIdentity,
      String manifestIdentity,
      String lockIdentity,
      String sourceInputIdentity,
      String buildInputIdentity,
      String toolchainIdentity,
      String dependencySetIdentity,
      String outputIdentity,
      long outputLength,
      String identity) {
    /** Rejects malformed identities and output extents before evidence publication. */
    public Evidence {
      requireIdentity(packageArchiveIdentity, "package archive identity");
      requireIdentity(manifestIdentity, "manifest identity");
      requireIdentity(lockIdentity, "lock identity");
      requireIdentity(sourceInputIdentity, "source input identity");
      requireIdentity(buildInputIdentity, "build input identity");
      requireIdentity(toolchainIdentity, "toolchain identity");
      requireIdentity(dependencySetIdentity, "dependency set identity");
      requireIdentity(outputIdentity, "output identity");
      requireIdentity(identity, "provenance identity");
      if (outputLength < 1 || MAX_OUTPUT_BYTES < outputLength) {
        throw new PackageFormatException("Package provenance output length is invalid");
      }
      String expectedIdentity = evidenceIdentity(
          packageArchiveIdentity,
          manifestIdentity,
          lockIdentity,
          sourceInputIdentity,
          buildInputIdentity,
          toolchainIdentity,
          dependencySetIdentity,
          outputIdentity,
          outputLength);
      if (!expectedIdentity.equals(identity)) {
        throw new PackageFormatException("Package provenance evidence identity mismatch");
      }
    }
  }

  /**
   * Verifies every declared provenance edge and returns evidence only after the complete pass.
   * The caller supplies the exact canonical target-source input used by {@code node}.
   */
  public static Evidence verify(
      PackageManifest manifest,
      byte[] packageArchive,
      PackageLock lock,
      BuildPlan plan,
      BuildPlan.Node node,
      byte[] targetSourceInput,
      BootstrapToolchain toolchain,
      OutputExpectation expectedOutput,
      byte[] output) {
    Objects.requireNonNull(manifest, "manifest");
    Objects.requireNonNull(packageArchive, "packageArchive");
    Objects.requireNonNull(lock, "lock");
    Objects.requireNonNull(plan, "plan");
    Objects.requireNonNull(node, "node");
    Objects.requireNonNull(targetSourceInput, "targetSourceInput");
    Objects.requireNonNull(toolchain, "toolchain");
    Objects.requireNonNull(expectedOutput, "expectedOutput");
    Objects.requireNonNull(output, "output");
    if (output.length < 1 || MAX_OUTPUT_BYTES < output.length) {
      throw new PackageFormatException("Package provenance output is outside the bound");
    }

    PackageArchive codec = new PackageArchive();
    PackageArchive.DecodedPackage decoded = codec.decode(packageArchive);
    if (!decoded.manifest().equals(manifest)) {
      throw new PackageFormatException("Package provenance manifest does not match archive");
    }
    byte[] canonicalArchive = codec.encode(decoded.manifest(), decoded.entries());
    if (!Arrays.equals(packageArchive, canonicalArchive)) {
      throw new PackageFormatException("Package provenance archive is not canonical");
    }

    String manifestIdentity = manifest.identity();
    if (!manifestIdentity.equals(lock.rootManifestIdentity())) {
      throw new PackageFormatException("Package provenance lock has another root manifest");
    }
    if (!plan.nodes().contains(node)) {
      throw new PackageFormatException("Package provenance node is outside its build plan");
    }
    if (!node.packageName().equals(manifest.name())
        || !node.packageVersion().equals(manifest.version())
        || !node.manifestIdentity().equals(manifestIdentity)) {
      throw new PackageFormatException("Package provenance build node names another package");
    }
    String sourceIdentity = sha256(targetSourceInput);
    if (!sourceIdentity.equals(node.sourceIdentity())) {
      throw new PackageFormatException("Package provenance target source changed");
    }

    Map<String, PackageLock.Entry> locked = new TreeMap<>();
    for (PackageLock.Entry entry : lock.entries()) {
      locked.put(entry.name(), entry);
    }
    List<String> declaredDependencies = manifest.dependencies().stream()
        .map(PackageManifest.Dependency::name)
        .toList();
    List<String> plannedDependencies = node.packageInputs().stream()
        .map(BuildPlan.PackageInput::name)
        .toList();
    if (!declaredDependencies.equals(plannedDependencies)) {
      throw new PackageFormatException("Package provenance dependency set changed");
    }
    for (BuildPlan.PackageInput input : node.packageInputs()) {
      PackageLock.Entry entry = locked.get(input.name());
      if (entry == null || !entry.archiveIdentity().equals(input.archiveIdentity())) {
        throw new PackageFormatException(
            "Package provenance dependency archive changed for " + input.name());
      }
    }

    String packageArchiveIdentity = decoded.identity();
    String lockIdentity = lock.identity();
    String buildInputIdentity = plan.buildInputIdentity(node);
    String toolchainIdentity = toolchain.identity();
    String dependencySetIdentity = dependencySetIdentity(node.packageInputs());
    String outputIdentity = sha256(output);
    if (!outputIdentity.equals(expectedOutput.identity())
        || output.length != expectedOutput.length()) {
      throw new PackageFormatException("Package provenance output changed");
    }
    String identity = evidenceIdentity(
        packageArchiveIdentity,
        manifestIdentity,
        lockIdentity,
        sourceIdentity,
        buildInputIdentity,
        toolchainIdentity,
        dependencySetIdentity,
        outputIdentity,
        output.length);
    return new Evidence(
        packageArchiveIdentity,
        manifestIdentity,
        lockIdentity,
        sourceIdentity,
        buildInputIdentity,
        toolchainIdentity,
        dependencySetIdentity,
        outputIdentity,
        output.length,
        identity);
  }

  private static String dependencySetIdentity(List<BuildPlan.PackageInput> inputs) {
    MessageDigest digest = sha256Digest();
    updateText(digest, "wheeler.package-inputs.v1");
    updateInt(digest, inputs.size());
    for (BuildPlan.PackageInput input : inputs) {
      updateText(digest, input.name());
      updateIdentity(digest, input.archiveIdentity());
    }
    return HexFormat.of().formatHex(digest.digest());
  }

  private static String evidenceIdentity(
      String packageArchiveIdentity,
      String manifestIdentity,
      String lockIdentity,
      String sourceIdentity,
      String buildInputIdentity,
      String toolchainIdentity,
      String dependencySetIdentity,
      String outputIdentity,
      long outputLength) {
    MessageDigest digest = sha256Digest();
    updateText(digest, DOMAIN);
    updateIdentity(digest, packageArchiveIdentity);
    updateIdentity(digest, manifestIdentity);
    updateIdentity(digest, lockIdentity);
    updateIdentity(digest, sourceIdentity);
    updateIdentity(digest, buildInputIdentity);
    updateIdentity(digest, toolchainIdentity);
    updateIdentity(digest, dependencySetIdentity);
    updateIdentity(digest, outputIdentity);
    updateLong(digest, outputLength);
    return HexFormat.of().formatHex(digest.digest());
  }

  private static String sha256(byte[] value) {
    return HexFormat.of().formatHex(sha256Digest().digest(value));
  }

  private static MessageDigest sha256Digest() {
    try {
      return MessageDigest.getInstance("SHA-256");
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void requireIdentity(String identity, String field) {
    if (identity == null || !identity.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException("Invalid " + field);
    }
  }

  private static void updateIdentity(MessageDigest digest, String identity) {
    digest.update(HexFormat.of().parseHex(identity));
  }

  private static void updateText(MessageDigest digest, String value) {
    byte[] encoded = value.getBytes(StandardCharsets.UTF_8);
    updateInt(digest, encoded.length);
    digest.update(encoded);
  }

  private static void updateInt(MessageDigest digest, int value) {
    digest.update(ByteBuffer.allocate(Integer.BYTES).putInt(value).array());
  }

  private static void updateLong(MessageDigest digest, long value) {
    digest.update(ByteBuffer.allocate(Long.BYTES).putLong(value).array());
  }
}
