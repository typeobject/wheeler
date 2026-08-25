package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Fixed application entry and semantic profiles carried by one capsule. */
public record CapsuleRoot(
    String packageInstance,
    String target,
    String rootWbc,
    String entryFunction,
    String runtimeProfile,
    String bytecodeProfile,
    String proofProfile,
    String targetProfile,
    String platformAbi,
    String executionLimits,
    NativeImagePlan.RuntimeMode runtimeMode,
    List<String> requiredCapabilities) {
  static final int MAX_CAPABILITIES = 32;
  static final int MAX_NAME_BYTES = 256;

  public CapsuleRoot {
    requireHash(packageInstance, "package instance");
    target = requireToken(target, "root target");
    rootWbc = requirePath(rootWbc, "root WBC");
    entryFunction = requireEntry(entryFunction);
    requireHash(runtimeProfile, "runtime profile");
    requireHash(bytecodeProfile, "bytecode profile");
    requireHash(proofProfile, "proof profile");
    requireHash(targetProfile, "target profile");
    requireHash(platformAbi, "platform ABI");
    requireHash(executionLimits, "execution limits");
    if (runtimeMode == null) {
      throw new PackageFormatException("Capsule runtime mode is required");
    }
    if (requiredCapabilities == null || requiredCapabilities.size() > MAX_CAPABILITIES) {
      throw new PackageFormatException("Invalid capsule capability count");
    }
    ArrayList<String> capabilities = new ArrayList<>(requiredCapabilities.size());
    Set<String> identities = new HashSet<>();
    String previous = null;
    for (String capability : requiredCapabilities) {
      String checked = requireToken(capability, "capability");
      if (!identities.add(checked) || previous != null && previous.compareTo(checked) >= 0) {
        throw new PackageFormatException("Capsule capabilities are duplicated or unordered");
      }
      capabilities.add(checked);
      previous = checked;
    }
    requiredCapabilities = List.copyOf(capabilities);
  }

  static String requirePath(String value, String description) {
    String path = PackageManifest.logicalPath(value);
    requireBytes(path, description);
    return path;
  }

  static String requireToken(String value, String description) {
    if (value == null
        || !value.matches("[a-z0-9][a-z0-9:._/@+\\-]*")
        || value.contains("//")) {
      throw new PackageFormatException("Invalid capsule " + description);
    }
    requireBytes(value, description);
    return value;
  }

  static void requireHash(String value, String description) {
    if (value == null || !value.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException("Invalid capsule " + description + " identity");
    }
  }

  private static String requireEntry(String value) {
    if (value == null
        || !value.matches("[A-Za-z_][A-Za-z0-9_]*(?:(?:\\.|::)[A-Za-z_][A-Za-z0-9_]*)*")) {
      throw new PackageFormatException("Invalid capsule entry function");
    }
    requireBytes(value, "entry function");
    return value;
  }

  private static void requireBytes(String value, String description) {
    if (value.getBytes(StandardCharsets.UTF_8).length > MAX_NAME_BYTES) {
      throw new PackageFormatException("Oversized capsule " + description);
    }
  }
}
