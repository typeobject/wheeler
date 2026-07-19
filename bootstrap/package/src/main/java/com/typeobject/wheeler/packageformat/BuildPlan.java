package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.PackageManifest.Capability;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Canonical, host-independent compilation plan for Wheeler package targets. */
public record BuildPlan(
    int schemaVersion,
    String workspaceIdentity,
    String compilerIdentity,
    String profile,
    List<Node> nodes) {
  public static final int SCHEMA_VERSION = 1;
  private static final int MAX_NODES = 100_000;

  public BuildPlan {
    if (schemaVersion != SCHEMA_VERSION
        || !hash(workspaceIdentity)
        || !hash(compilerIdentity)) {
      throw new PackageFormatException("Invalid build plan header");
    }
    requireName(profile, "build profile");
    if (nodes.size() > MAX_NODES) {
      throw new PackageFormatException("Build plan has too many nodes");
    }
    List<Node> ordered = new ArrayList<>(List.copyOf(nodes));
    ordered.sort(Comparator.comparing(Node::packageName)
        .thenComparing(Node::targetName)
        .thenComparing(Node::outputPath));
    Set<String> outputs = new HashSet<>();
    Set<String> identities = new HashSet<>();
    for (Node node : ordered) {
      if (!outputs.add(node.outputPath())) {
        throw new PackageFormatException("Colliding build output " + node.outputPath());
      }
      if (!identities.add(node.identity())) {
        throw new PackageFormatException("Duplicate build node identity " + node.identity());
      }
    }
    nodes = List.copyOf(ordered);
  }

  public record Node(
      String identity,
      String packageName,
      String packageVersion,
      String manifestIdentity,
      String targetName,
      TargetKind targetKind,
      String sourceIdentity,
      String outputPath,
      List<PackageInput> packageInputs,
      List<Capability> capabilityRequests,
      ExecutionLimits executionLimits,
      List<Capability> capabilityGrants) {
    public Node {
      requireName(packageName, "package");
      SemanticVersion.parse(packageVersion);
      if (!hash(manifestIdentity) || !hash(sourceIdentity)) {
        throw new PackageFormatException("Invalid build node content identity");
      }
      requireName(targetName, "target");
      Objects.requireNonNull(targetKind, "targetKind");
      logicalPath(outputPath);
      List<PackageInput> inputs = new ArrayList<>(List.copyOf(packageInputs));
      inputs.sort(Comparator.comparing(PackageInput::name));
      if (new HashSet<>(inputs.stream().map(PackageInput::name).toList()).size()
          != inputs.size()) {
        throw new PackageFormatException("Duplicate package input for " + packageName);
      }
      packageInputs = List.copyOf(inputs);
      capabilityRequests = canonicalCapabilities(
          capabilityRequests, "request", packageName);
      Objects.requireNonNull(executionLimits, "executionLimits");
      capabilityGrants = canonicalCapabilities(capabilityGrants, "grant", packageName);
      if (!capabilityRequests.containsAll(capabilityGrants)) {
        throw new PackageFormatException(
            "Capability grant exceeds requests for " + packageName);
      }
      String expected = nodeIdentity(
          packageName,
          packageVersion,
          manifestIdentity,
          targetName,
          targetKind,
          sourceIdentity,
          outputPath,
          packageInputs,
          capabilityRequests,
          executionLimits,
          capabilityGrants);
      if (!expected.equals(identity)) {
        throw new PackageFormatException("Build node identity mismatch for " + packageName
            + ":" + targetName);
      }
    }

    public static Node create(
        String packageName,
        String packageVersion,
        String manifestIdentity,
        String targetName,
        TargetKind targetKind,
        String sourceIdentity,
        String outputPath,
        List<PackageInput> packageInputs,
        List<Capability> capabilityRequests,
        ExecutionLimits executionLimits,
        List<Capability> capabilityGrants) {
      List<PackageInput> inputs = packageInputs.stream()
          .sorted(Comparator.comparing(PackageInput::name))
          .toList();
      List<Capability> requests = canonicalCapabilities(
          capabilityRequests, "request", packageName);
      List<Capability> grants = canonicalCapabilities(
          capabilityGrants, "grant", packageName);
      return new Node(
          nodeIdentity(
              packageName,
              packageVersion,
              manifestIdentity,
              targetName,
              targetKind,
              sourceIdentity,
              outputPath,
              inputs,
              requests,
              executionLimits,
              grants),
          packageName,
          packageVersion,
          manifestIdentity,
          targetName,
          targetKind,
          sourceIdentity,
          outputPath,
          inputs,
          requests,
          executionLimits,
          grants);
    }
  }

  public record ExecutionLimits(
      long maxSteps,
      long maxMemoryBytes,
      long maxInputBytes,
      long maxOutputBytes,
      long timeoutMillis) {
    public static final ExecutionLimits DEFAULT = new ExecutionLimits(
        10_000_000L,
        256L * 1024 * 1024,
        64L * 1024 * 1024,
        64L * 1024 * 1024,
        60_000L);

    public ExecutionLimits {
      if (maxSteps <= 0 || maxSteps > 1_000_000_000_000L
          || maxMemoryBytes <= 0 || maxMemoryBytes > (1L << 40)
          || maxInputBytes <= 0 || maxInputBytes > (1L << 40)
          || maxOutputBytes <= 0 || maxOutputBytes > (1L << 40)
          || timeoutMillis <= 0 || timeoutMillis > 86_400_000L) {
        throw new PackageFormatException("Invalid build execution limits");
      }
    }
  }

  public record PackageInput(String name, String archiveIdentity) {
    public PackageInput {
      requireName(name, "package input");
      if (!hash(archiveIdentity)) {
        throw new PackageFormatException("Invalid package input identity");
      }
    }
  }

  private static String nodeIdentity(
      String packageName,
      String packageVersion,
      String manifestIdentity,
      String targetName,
      TargetKind targetKind,
      String sourceIdentity,
      String outputPath,
      List<PackageInput> inputs,
      List<Capability> requests,
      ExecutionLimits limits,
      List<Capability> grants) {
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    field(bytes, "wheeler-build-node-1");
    field(bytes, packageName);
    field(bytes, packageVersion);
    field(bytes, manifestIdentity);
    field(bytes, targetName);
    field(bytes, targetKind.name());
    field(bytes, sourceIdentity);
    field(bytes, outputPath);
    field(bytes, Integer.toString(inputs.size()));
    for (PackageInput input : inputs) {
      field(bytes, input.name());
      field(bytes, input.archiveIdentity());
    }
    field(bytes, Integer.toString(requests.size()));
    for (Capability capability : requests) {
      field(bytes, capability.name());
      field(bytes, capability.pattern());
    }
    field(bytes, Long.toString(limits.maxSteps()));
    field(bytes, Long.toString(limits.maxMemoryBytes()));
    field(bytes, Long.toString(limits.maxInputBytes()));
    field(bytes, Long.toString(limits.maxOutputBytes()));
    field(bytes, Long.toString(limits.timeoutMillis()));
    field(bytes, Integer.toString(grants.size()));
    for (Capability capability : grants) {
      field(bytes, capability.name());
      field(bytes, capability.pattern());
    }
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(bytes.toByteArray()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static List<Capability> canonicalCapabilities(
      List<Capability> capabilities, String description, String packageName) {
    List<Capability> result = new ArrayList<>(List.copyOf(capabilities));
    result.sort(Comparator.comparing(Capability::name).thenComparing(Capability::pattern));
    if (new HashSet<>(result).size() != result.size()) {
      throw new PackageFormatException(
          "Duplicate capability " + description + " for " + packageName);
    }
    return List.copyOf(result);
  }

  private static void field(ByteArrayOutputStream output, String value) {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    output.write(bytes.length);
    output.write(bytes.length >>> 8);
    output.write(bytes.length >>> 16);
    output.write(bytes.length >>> 24);
    output.writeBytes(bytes);
  }

  private static boolean hash(String value) {
    return value != null && value.matches("[0-9a-f]{64}");
  }

  private static void requireName(String value, String description) {
    if (value == null || !value.matches("[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*")) {
      throw new PackageFormatException("Invalid " + description + " name " + value);
    }
  }

  private static void logicalPath(String path) {
    if (path == null || path.isEmpty() || path.startsWith("/") || path.endsWith("/")
        || path.indexOf('\\') >= 0 || path.indexOf('\0') >= 0) {
      throw new PackageFormatException("Invalid build output path " + path);
    }
    for (String component : path.split("/", -1)) {
      if (component.isEmpty() || component.equals(".") || component.equals("..")) {
        throw new PackageFormatException("Invalid build output path " + path);
      }
    }
  }
}
